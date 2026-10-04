# Contributing

Thanks for helping out. This project is run by the UCLA Library Data Science Center and maintained in part by student contributors through the DSC's open source program. You don't need prior experience with servers, Ansible, or 3D data. You do need to be willing to ask questions.

## First time here

1. Get staging running on your laptop: [docs/getting-started.md](docs/getting-started.md).
2. Skim the [README](README.md) to see how the pieces fit.
3. Pick something from the issue tracker labeled **good first issue**, or from [docs/project-ideas.md](docs/project-ideas.md). Comment on the issue so nobody else picks the same one.

## How a change gets in

1. **Branch.** `git switch -c short-description`
2. **Change and test locally.** `pixi run staging-up` to see it, `pixi run test` before you push.
3. **Commit.** Hooks run the linters automatically. Write a message that says why, not just what.
4. **Open a pull request.** Fill in what you changed, how you tested it, and a screenshot if it's visible.
5. **Review.** A DSC staff member reviews every PR. Expect questions; they're how we both learn. Small PRs get reviewed faster than big ones.
6. **Deploy.** Staff deploy merged changes to production. You'll never need production access to contribute.

## Kinds of contributions

- **Server and config** (`ansible/`, `terraform/`): Apache, TLS, security, monitoring.
- **The listing page and branding** (`ansible/roles/potree/files/branding/`): HTML and CSS, accessibility, mobile layout.
- **Collections** (`content/collections/`): new viewer pages for DSC scans. Point cloud data goes in S3, not git.
- **Potree itself**: the viewer is open source and we'd like to fix things upstream. See [docs/hacking-on-potree.md](docs/hacking-on-potree.md).
- **Docs**: if a step confused you, fixing that doc is a real contribution. The next student will thank you.

## Ground rules

- Be kind, patient and specific. See the [Code of Conduct](CODE_OF_CONDUCT.md).
- Don't commit secrets, keys, or anything from `terraform.tfvars`. The hooks catch some of this, not all.
- Don't edit someone else's collection pages without checking with them.
- Using AI tools is fine. You're responsible for understanding and testing what you submit, and say so in the PR if a tool wrote a meaningful part of it.

## Getting help

Open an issue, comment on your PR, or ask in the DSC channel. Email: datascience@ucla.edu.
