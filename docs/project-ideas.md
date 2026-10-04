# Project ideas

Projects sized for student contributors, roughly easiest first. Each one should end in a pull request. Before starting, open an issue (or comment on an existing one) so we can talk scope. These are starting points, not specs.

## Starter (a few hours to a week)

**Remove dead library references from collection pages.**
Several pages under `content/collections/Iceland/` load `../libs/perfect-scrollbar/...`, which doesn't exist in Potree 1.8.2 and already returns 404 on the live site. Confirm the pages work without it, remove the references, and check them in staging.
*Skills:* HTML, browser dev tools.

**Check collection pages automatically.**
Write a script (and add it to `pixi run lint`) that finds every `../build/...` and `../libs/...` path referenced by a collection page and confirms it exists in the pinned Potree release. It would have caught the problem above.
*Skills:* Python or shell, CI.

**Accessibility pass on the listing page.**
Audit `https://localhost:8443/` with a screen reader and an automated checker (axe, Lighthouse). Folder icons have alt text like `[DIR]`, and keyboard focus styles are missing. Fix what you find in the branding CSS/HTML.
*Skills:* HTML/CSS, WCAG basics.

**Mobile layout.**
Make the listing and header work well at phone width.
*Skills:* CSS.

**Improve a doc.**
Follow [getting-started.md](getting-started.md) on a fresh machine (Windows/WSL especially) and fix every place you got stuck.

## Intermediate (a few weeks)

**Collection landing page.**
Replace the bare directory listing with a page that shows each collection's title, description, creator, license and a thumbnail. Idea: a small `collection.yml` per folder, rendered by Ansible into an index page. Keep the raw listing available.
*Skills:* YAML, Jinja templates, design.

**COPC pipeline.**
Potree 1.8.2 can load [COPC](https://copc.io/) files directly from S3, skipping PotreeConverter. Take one DSC scan, convert it to COPC with [PDAL](https://pdal.io/) or untwine, host it in S3, and build a viewer page for it. Write up how load time and quality compare with the converted version.
*Skills:* command-line data tools, 3D data, some JavaScript.

**Terraform tests without AWS.**
Use `terraform test` with mock providers to check the cutover logic (`eip_target = "new"` points the Elastic IP at the new instance, the SSH rule refuses `0.0.0.0/0`) in CI, with no AWS credentials.
*Skills:* Terraform.

**Disk and certificate alarms on the server.**
The 2026 outage was a full disk. Add monitoring that alerts before it happens again (CloudWatch agent + alarm, or a lighter check).
*Skills:* Ansible, AWS.

**Bring the S3 buckets under Terraform.**
The point cloud data buckets (`potree-test2`, `potree1`) were created by hand. Import them, document their CORS settings, and decide on naming.
*Skills:* Terraform, AWS.

## Upstream Potree (open-ended)

**Triage with our data.**
Pick open issues in [potree/potree](https://github.com/potree/potree/issues), try to reproduce them on 1.8.2 using DSC collections, and comment with what you found. Reproductions are valuable to a backlogged project even without a fix.

**Review open pull requests.**
Build a PR branch, test it in staging (see [hacking-on-potree.md](hacking-on-potree.md)), and leave a review saying what you tested and what happened.

**Fix something that bothers our users.**
If a DSC collection hits a viewer bug, fix it in Potree, open the upstream PR, and we'll consider carrying it in a DSC fork until it merges.

**Document PotreeConverter for library use.**
Build PotreeConverter, convert a DSC scan, and write the guide you wish existed. Contribute the generally useful parts upstream.
