/**
 * The FaFo wordmark with the second "F" mirrored horizontally, matching the
 * brand logo (see public/assets-temp/fafo-brand-logo.png). Use this anywhere
 * the brand name is shown as visible text so the flipped F stays consistent.
 *
 * The rendered text content is still "FaFo", so screen readers and copy/paste
 * read normally — only the glyph is mirrored visually.
 */
export function Wordmark({ className }: { className?: string }) {
  return (
    <span className={className}>
      Fa<span className="flip-f">F</span>o
    </span>
  )
}
