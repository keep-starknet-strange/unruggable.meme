<div align="center">
  <h1 align="center">🚀 Unruggable interface</h1>
</div>


## Build


> Warning: You should do these operations all in the `/frontend` folder, not in the root folder of Unruggable-meme project.

To build the Unruggable interface, you need to install [Node.js](https://nodejs.org/en) and [NPM](https://www.npmjs.com/). We suggest you using `20.10.0 LTS`.

You can do it manually, but we suggest you install Node and NPM using [NVM](https://github.com/nvm-sh/nvm).

After you installed nvm, run:
```
nvm install --lts
```

Next, you need to install [TypeScript](https://www.typescriptlang.org/). Run the following command:
```
npm i typescript@~4 
```

Afterward, execute:
```
npm install
```
This will install all dependencies.

To build the front-end, use the following command:
```
npm run build
```

For running a local development server, execute:
```
npm run start
```

## Contribution
### Code format
We are using [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint) and [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) to format our code. 
We recommend that you also install them to maintain clean and readable code.