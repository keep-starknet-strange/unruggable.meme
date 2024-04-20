import colors from "colors";
import { deployFactory, deployTokenLocker } from "./libs/contract.js";

const MIN_LOCK_TIME = 15_721_200; // 6 months

const main = async () => {
  console.log(`   ____          _         `.red);
  console.log(`  |    \\ ___ ___| |___ _ _ `.red);
  console.log(`  |  |  | -_| . | | . | | |`.red);
  console.log(`  |____/|___|  _|_|___|_  |`.red);
  console.log(`            |_|       |___|`.red);

  // Token Locker
  console.log(`\n${"Deploying TokenLocker contract".blue}`);
  await deployTokenLocker(MIN_LOCK_TIME);

  // Factory
  console.log(`\n${"Deploying Factory contract".blue}`);
  await deployFactory();
};

main();
