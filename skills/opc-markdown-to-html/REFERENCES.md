# References

This skill is maintained as an OPC-owned formatter. Internal path names use OPC-owned naming rather than external project branding.

## Referenced and Adapted Parts

- Markdown-to-HTML conversion pipeline structure
- Theme loading and CSS inlining approach
- Frontmatter parsing and title/summary extraction flow
- WeChat-oriented theme and publishing workflow ideas

## What Was Changed for OPC

- Renamed the internal rendering core to `opc-md-core`
- Added and maintained OPC-specific templates such as `opc-briefing`, `opc-editorial`, `opc-default`, and `opc-report`
- Reworked defaults, article assumptions, and publishing guidance around OPC community writing
- Added `.opc-skills/opc-markdown-to-html/EXTEND.md` as the preferred config namespace
- Kept legacy config lookup only as a compatibility fallback

## Attribution Practice

- Keep this file updated when borrowing implementation ideas or adapting structure from external tools
- Describe referenced components at the capability or module level, instead of carrying external branding into internal paths
