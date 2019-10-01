This repo has journal entries and blog entries in separate sections.

    content/journal
           /blog

I would like for only the `blog` entries to show up on the top page.

In `THEME/layouts.html`, I tried [`{{ range where .Paginator.Pages "Section" "blog" }}`](https://github.com/thunderrabbit/barefoot_rob/blob/a78e8d288dcb7137c002722332b2f08754d258df/themes/purehugo-augmentation/layouts/index.html#L11)

That didn't work, so I tried [sending the pagination variable to the pagination.html partial](https://github.com/thunderrabbit/barefoot_rob/commit/3e5a1d6cc6f4bef8277efdb53d85a48f88f3ad4a#diff-93f892dedc737343c346fa10d4950db9)

SOLVED!   https://gohugo.io/functions/where/#mainsections
