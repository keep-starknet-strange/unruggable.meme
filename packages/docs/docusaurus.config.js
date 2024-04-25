// @ts-check
// `@type` JSDoc annotations allow editor autocompletion and type checking
// (when paired with `@ts-check`).
// There are various equivalent ways to declare your Docusaurus config.
// See: https://docusaurus.io/docs/api/docusaurus-config

import {themes as prismThemes} from 'prism-react-renderer';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Unruggable Meme',
  tagline: 'Tired of getting rugpulled? Introducing Unruggable Meme, a memecoin standard and deployment tool designed to ensure a maximum safety for memecoin traders.',
  favicon: '/favicon/android-chrome-512x512.png',

  // Set the production url of your site here
  url: 'https://www.unruggable.meme/',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'Unruggable Meme', // Usually your GitHub org/user name.
  projectName: 'Unruggable Meme', // Usually your repo name.

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.js',
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/keep-starknet-strange/unruggable.meme',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      // Replace with your project's social card
      image: 'https://github.com/keep-starknet-strange/unruggable.meme/blob/main/assets/logo/logo.png?raw=true',
      navbar: {
        title: 'Unruggable Meme', //Name of site at top left corner
        logo: {
          alt: 'Unruggable Meme Logo',
          src: 'https://github.com/keep-starknet-strange/unruggable.meme/blob/main/assets/logo/logo.png?raw=true',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'tutorialSidebar',
            position: 'left',
            label: 'Documentation',
          },
          {
            href: 'https://github.com/keep-starknet-strange/unruggable.meme',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Community',
            items: [
              {
                label: 'Github',
                href: 'https://github.com/keep-starknet-strange/unruggable.meme',
              },
              {
                label: 'Telegram',
                href: 'https://t.me/UnruggableMeme',
              },
              {
                label: 'Twitter',
                href: 'https://twitter.com/UnrugMemec0in',
              },
            ],
          },
          {
            title: 'More',
            items: [
              // {
              //   label: 'Blog',
              //   to: '/blog',
              // },
              {
                label: 'GitHub',
                href: 'https://github.com/keep-starknet-strange/unruggable.meme',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} Unruggable Meme. Built with Docusaurus.`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
      },
    }),
};

export default config;
