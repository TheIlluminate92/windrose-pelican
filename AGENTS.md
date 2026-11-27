# Repository worker instructions

Scope: TheIlluminate92/windrose-pelican.

Read [README.md](README.md) for deployment and verification boundaries and
[PELICAN-SUBMISSION.md](PELICAN-SUBMISSION.md) for the separate upstream process.
Preserve the publisher's original game files and the adapter-only image boundary.
Keep private server data, credentials, saves, and player identifiers out of issue
reports and pull requests.

## Git workflow

Link or open an issue, fetch the current default branch, and create one branch
per change. Push that branch and open a pull request against `main` with the test
results and any remaining verification limits. Use `Closes #NN` only when the
merge resolves the issue.

GitHub requires a pull request and squash merging into the default branch.
Current approvals, release decisions, and operating permissions still apply.
Preserve a branch while another change depends on it, and update the relevant
existing handoff after meaningful changes.

For routine PR verification, run `PYTHONPATH=. python3 -m unittest discover -s tests -v`
from the repository root on Linux. Record publisher-image integration, registry builds,
and live Pelican checks separately. Before merging, account for the registry
publisher triggered by updates to `main`. Record the exact source tag or commit
and the deployed image digest separately.
