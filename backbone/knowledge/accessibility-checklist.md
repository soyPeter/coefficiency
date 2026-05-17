# Accessibility Checklist

WCAG 2.1 AA verification for user interfaces.

## Keyboard Navigation

- [ ] All interactive elements are keyboard accessible
- [ ] Tab order is logical
- [ ] Focus indicators are visible
- [ ] No keyboard traps
- [ ] Escape key closes modals/dropdowns

## Screen Readers

- [ ] All images have alt text
- [ ] Form inputs have labels
- [ ] Headings are hierarchical (h1 → h2 → h3)
- [ ] ARIA labels where needed
- [ ] Live regions for dynamic content
- [ ] Role attributes correct

## Visual Design

- [ ] Color contrast >= 4.5:1 (normal text)
- [ ] Color contrast >= 3:1 (large text)
- [ ] Color is not sole indicator of state
- [ ] Text can be resized to 200%
- [ ] Content still readable at 320px width

## ARIA

- [ ] `aria-label` on icon-only buttons
- [ ] `aria-expanded` on collapsible content
- [ ] `aria-live` on status updates
- [ ] `role` correct for custom components
- [ ] No redundant ARIA (e.g., `role="button"` on `<button>`)

## Testing Tools

- [ ] axe-core passes
- [ ] Lighthouse accessibility >= 90
- [ ] Manual keyboard navigation test
- [ ] Screen reader test (NVDA, JAWS, VoiceOver)

## Common Issues

| Issue | Fix |
|-------|-----|
| Missing alt text | Add descriptive alt |
| Empty links | Add aria-label or visible text |
| Low contrast | Adjust colors to meet ratios |
| Missing form labels | Add `<label>` or aria-label |
| Focus not visible | Add focus styles |
| Skipped heading levels | Maintain hierarchy |
