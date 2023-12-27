<div align="center">
  <h1 align="center">🚀 Unruggable interface</h1>
</div>


## Build


> Warning: You should do these operations all in the `/frontend` folder, not in the root folder of Unruggable-meme project.

To build the Unruggable interface, you need to install [Node.js](https://nodejs.org/en), [NPM](https://www.npmjs.com/) and [YARN](https://yarnpkg.com/). We suggest you using `20.10.0 LTS` node version.
You can do it manually, but we suggest you install Node and NPM using [NVM](https://github.com/nvm-sh/nvm).

After you installed nvm, run:
```
nvm install --lts
```

Install yarn dependency manager globally:
```
npm install -g yarn
```

Go to `unruggable.meme/frontend` directory and execute:
```
yarn install
```
This will install all the dependencies. Find some useful yarn cli commands [here](https://yarnpkg.com/cli).

To build the front-end, use the following command:
```
yarn build
```
You can also check `scripts` within `package.json` file to know the exact command used for build.

For running a local development server, execute:
```
yarn start
```

## Contribution
### Code format
We use [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint) and [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) to format our code. 
We recommend that you also install them to maintain clean and readable code. You can learn how to do that [here](https://www.aleksandrhovhannisyan.com/blog/format-code-on-save-vs-code-eslint/).
