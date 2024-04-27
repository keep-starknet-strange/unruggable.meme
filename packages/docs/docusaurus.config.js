require('dotenv').config()

module.exports = {
  customFields: {
    // Analytics proxy URL
    analyticsProxyUrl: process.env.REACT_APP_AMPLITUDE_PROXY_URL,
    // From node
    nodeEnv: process.env.NODE_ENV,
  },
  title: 'Unruggable meme',
  tagline: 'Documentation and Guides',
  url: 'https://docs.unruggable.meme',
  baseUrl: '/',
  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'ignore',
  favicon: 'img/favicon.ico',
  organizationName: 'Keep Starknet Strange', // Usually your GitHub org/user name.
  projectName: 'Unruggable-docs', // Usually your repo name.
  themeConfig: {
    image: 'img/twitter_card_bg.jpg',
    prism: {
      additionalLanguages: ['rust'],
    },
    navbar: {
      title: 'Unruggable Docs',
      logo: {
        alt: 'Unruggable Wings',
        src: 'img/logo.svg',
      },
      items: [
        {
          to: '/tutorial/overview',
          label: 'Tutorial',
          position: 'left',
          className: 'active',
        },
        {
          to: '/concepts/overview',
          label: 'Concepts',
          position: 'left',
          className: 'active',
        },
        {
          to: '/contracts/overview',
          label: 'Contracts',
          position: 'left',
          className: 'active',
        },
        {
          to: '/sdk/core/overview',
          label: 'SDKs',
          position: 'left',
          className: 'active',
        },
        {
          href: 'https://github.com/keep-starknet-strange/unruggable.meme',
          label: 'GitHub',
          position: 'right',
          className: 'persistent',
        },
        {
          href: 'https://app.onlydust.com/p/unruggable-meme',
          label: 'OnlyDust',
          position: 'right',
          className: 'persistent',
        },
      ],
    },
    footer: {
      // style: "dark",
      links: [
        {
          title: 'Github',
          items: [
            {
              label: 'frontend',
              href: 'https://github.com/keep-starknet-strange/unruggable.meme/tree/main/packages/frontend',
            },
            {
              label: 'contracts',
              href: 'https://github.com/keep-starknet-strange/unruggable.meme/tree/main/packages/contracts',
            },
            {
              label: 'backend',
              href: 'https://github.com/keep-starknet-strange/unruggable.meme/tree/main/packages/backend',
            },
            {
              label: 'packages',
              href: 'https://github.com/keep-starknet-strange/unruggable.meme/tree/main/packages',
            },
          ],
        },
        {
          title: 'Ecosystem',
          items: [
            {
              label: 'App',
              href: 'https://unruggable.meme/',
            },
          ],
        },
        {
          title: 'Community',
          items: [
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
      ],
      // copyright: `unlicensed`,
    },
    colorMode: {
      // "light" | "dark"
      defaultMode: 'dark',

      // Hides the switch in the navbar
      // Useful if you want to support a single color mode
      disableSwitch: false,

      // Should we use the prefers-color-scheme media-query,
      // using user system preferences, instead of the hardcoded defaultMode
      respectPrefersColorScheme: true,
    },
  },
  presets: [
    [
      '@docusaurus/preset-classic',
      {
        docs: {
          routeBasePath: '/',
          sidebarPath: require.resolve('./sidebars.js'),
          editUrl: 'https://github.com/keep-starknet-strange/unruggable.meme/tree/main/packages/docs',
          includeCurrentVersion: true,
        },
        theme: {
          customCss: ['./src/css/custom.css', './src/css/colors.css'],
        },
      },
    ],
  ],
  plugins: [['@saucelabs/theme-github-codeblock', {}]],
}
