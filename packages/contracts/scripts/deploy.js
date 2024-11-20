/* import colors from 'colors' */
import { deployFactory, deployLockManager, deployEkuboLauncher } from './libs/contract.js'

const MIN_LOCK_TIME = 15_721_200 // 6 months

const main = async () => {
  console.log(`   ____          _         `.red)
  console.log(`  |    \\ ___ ___| |___ _ _ `.red)
  console.log(`  |  |  | -_| . | | . | | |`.red)
  console.log(`  |____/|___|  _|_|___|_  |`.red)
  console.log(`            |_|       |___|`.red)

  // Token Locker
  // console.log(`\n${'Deploying LockManager contract'.blue}`)
  // await deployLockManager(MIN_LOCK_TIME, "0x013d8ed1df7eae07a2ea97fc23d6f2e99717a0d4f686dfb5c16e67aa1a806ced")

  // console.log(`\n${'Deploying Ekubo launcher contract'.blue}`)
  // const ekuboLauncherAddress = await deployEkuboLauncher();

  // Factory
   console.log(`\n${'Deploying Factory contract'.blue}`)
   await deployFactory("0x011d74272a1f83791cfAb19702AE28ba396f9A5cF8a5A689eb1C88C32419fe02", "0x01aE6B1EB0B2a1B0F1c3cC75Af16402AE98EE696B6A5633f8b03D31519300175")
}

main()
