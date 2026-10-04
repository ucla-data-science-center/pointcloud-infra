# Hacking on Potree

pointcloud.ucla.edu runs [Potree](https://github.com/potree/potree), an open source WebGL point cloud viewer written in JavaScript. Fixing a bug or adding a feature in Potree helps every site that uses it, not just ours. This page covers how to work on Potree locally and how to think about contributing back.

## Know the project before you contribute

As of October 2026:

- **potree/potree** (the viewer, BSD-2-Clause): about 5,600 stars, 1,300+ forks, and a large open issue backlog. The last code merge was May 2024, and roughly 85 pull requests are open. It is widely used but effectively in maintenance mode.
- **potree/PotreeConverter** (turns LAS/LAZ scans into Potree's format): actively developed by the original author, with commits as recent as September 2026. Outside pull requests are merged rarely.
- **Potree 1.8.2 can load COPC** (Cloud Optimized Point Cloud) files directly, which can skip the conversion step entirely.

This is common in open source: a successful project, one main author, more users than maintainers. Contributing well here means:

1. **Search before you file.** Your bug may already have an issue (and a fix in an unmerged PR).
2. **Reproduce precisely.** A minimal example (browser, Potree version, a small public dataset, steps) is valuable even without a fix. Maintainers merge what they can verify quickly.
3. **Keep PRs small** and focused on one thing.
4. **Don't wait on a merge to use your fix.** We carry fixes in the DSC fork (see below) and deploy from it, while the upstream PR stays open for everyone else.
5. **Review other people's open PRs.** Testing and commenting on an existing PR ("I confirmed this fixes #123 on Firefox 140") is one of the most useful things you can do for a backlogged project.

## Set up Potree locally

You need Node.js (any current LTS release; tested with Node 26).

```bash
git clone https://github.com/potree/potree.git ~/src/potree
cd ~/src/potree
npm install          # also builds, into build/potree/
```

Once `npm install` finishes, `build/potree/potree.js` exists. That's the file the site loads.

## See your build in staging

From this repo, with staging running (`pixi run staging-up`):

```bash
pixi run staging-potree-dev ~/src/potree
```

Staging now serves your build instead of the 1.8.2 release. Open <https://localhost:8443/> and load a collection. Your browser's developer console prints the Potree version on load, which is a quick way to confirm you're on your build.

The loop:

1. Edit files under `~/src/potree/src/`.
2. `npm run build` in the Potree checkout.
3. `pixi run staging-potree-dev ~/src/potree`, then reload the page (hard refresh: Cmd+Shift+R / Ctrl+Shift+R).

For faster iteration on viewer code alone, `npm start` in the Potree checkout runs a watcher that rebuilds as you save, and Potree's own `examples/` folder works with any local web server. Use staging when you need to see our real collections and Apache setup.

To go back to the release: `pixi run staging-up`.

## Contributing a fix upstream

1. Fork `potree/potree` on GitHub (or use the DSC fork once it exists, see below) and clone your fork.
2. Branch from `develop` (Potree's default branch).
3. Make the change, build, and test it in staging against at least two collections.
4. Open a PR to `potree/potree` describing the problem, the fix, and how you tested it. Link the issue.
5. Tell us in the DSC channel, and add the PR to the tracking issue in this repo, so we can decide whether to carry it in our fork meanwhile.

## The DSC fork (planned)

The plan is a `ucla-data-science-center/potree` fork that carries fixes we need before upstream merges them. When that exists, the role will gain an option to deploy a tagged build from the fork, through the same test process as a release upgrade. Until then, use your personal fork.

## Good places to start

See [project-ideas.md](project-ideas.md) for Potree-related projects sized for students.
