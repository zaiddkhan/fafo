"""Test fixtures: an in-memory Firestore good enough for the notification engine.

It supports exactly the operations the notification modules use: document get/set/
update/delete, subcollections, equality `where` + `limit` + `stream`, and a transaction
object compatible with our runtime-decorated `@firestore.transactional` inner functions
(we monkeypatch `firestore.transactional` to a passthrough so it drives the fake txn).
"""

import copy

import pytest
from google.cloud import firestore as gcf

import app.notifications.outbox as outbox_mod
import app.notifications.rate_limit as rl_mod


# --- In-memory Firestore --------------------------------------------------------


class _Snap:
    def __init__(self, doc):
        self._doc = doc
        self.id = doc.id
        self.reference = doc

    @property
    def exists(self):
        return self._doc._data is not None

    def to_dict(self):
        return copy.deepcopy(self._doc._data) if self._doc._data is not None else None


class FakeDoc:
    def __init__(self, parent_coll, doc_id):
        self._coll = parent_coll
        self.id = doc_id
        self._data = None
        self._subcolls = {}

    @property
    def reference(self):
        return self

    def get(self, transaction=None):
        return _Snap(self)

    def set(self, data, merge=False):
        if merge and self._data is not None:
            self._data.update(copy.deepcopy(data))
        else:
            self._data = copy.deepcopy(data)

    def update(self, data):
        if self._data is None:
            self._data = {}
        self._data.update(copy.deepcopy(data))

    def delete(self):
        self._data = None

    def collection(self, name):
        return self._subcolls.setdefault(name, FakeCollection())


class _Query:
    def __init__(self, docs):
        self._docs = docs

    def where(self, field, op, value):
        assert op == "==", "fake only supports == filters"
        return _Query([d for d in self._docs if (d._data or {}).get(field) == value])

    def limit(self, n):
        return _Query(self._docs[:n])

    def stream(self):
        return [_Snap(d) for d in self._docs if d._data is not None]


class FakeCollection:
    def __init__(self):
        self._docs = {}
        self._auto = 0

    def document(self, doc_id=None):
        if doc_id is None:
            self._auto += 1
            doc_id = f"auto{self._auto}"
        return self._docs.setdefault(doc_id, FakeDoc(self, doc_id))

    def _live_docs(self):
        return [d for d in self._docs.values() if d._data is not None]

    def where(self, field, op, value):
        return _Query(self._live_docs()).where(field, op, value)

    def limit(self, n):
        return _Query(self._live_docs()).limit(n)

    def stream(self):
        return [_Snap(d) for d in self._live_docs()]


class FakeTransaction:
    """Drives the fake store directly; ordering/atomicity is single-threaded in tests."""

    def get(self, ref, **kw):
        return ref.get()

    def set(self, ref, data, merge=False):
        ref.set(data, merge=merge)

    def update(self, ref, data):
        ref.update(data)

    def delete(self, ref):
        ref.delete()


class FakeFirestore:
    def __init__(self):
        self._colls = {}

    def collection(self, name):
        return self._colls.setdefault(name, FakeCollection())

    def transaction(self):
        return FakeTransaction()


def _passthrough_transactional(func):
    def wrapper(transaction, *a, **k):
        return func(transaction, *a, **k)
    return wrapper


@pytest.fixture
def db(monkeypatch):
    """A fresh in-memory Firestore, wired into every module that calls get_firestore."""
    fake = FakeFirestore()

    def _get():
        return fake

    # The notification engine resolves the client lazily via get_firestore in each module.
    monkeypatch.setattr("app.notifications.service.get_firestore", _get, raising=False)
    monkeypatch.setattr("app.notifications.scheduler.get_firestore", _get, raising=False)
    monkeypatch.setattr("app.firebase.get_firestore", _get, raising=False)

    # Make the runtime-applied @firestore.transactional drive the fake transaction.
    monkeypatch.setattr(outbox_mod.firestore, "transactional", _passthrough_transactional)
    monkeypatch.setattr(rl_mod.firestore, "transactional", _passthrough_transactional)
    return fake


@pytest.fixture
def captured_fcm(monkeypatch):
    """Capture FCM sends; configurable result per call."""
    from app.notifications import fcm

    calls = []
    box = {"result": fcm.SendResult(success_count=1)}

    def _send(tokens, **kwargs):
        calls.append({"tokens": list(tokens), **kwargs})
        return box["result"]

    monkeypatch.setattr("app.notifications.service.fcm.send_to_tokens", _send)
    return {"calls": calls, "box": box}
