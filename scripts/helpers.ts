import { ethers } from 'hardhat'
import { DeploymentConfigStruct } from '../typechain-types/contracts/ERC721S'


export const deployMinimalErc721S = async ({
    name = 'TestToken',
    symbol = 'TEST',
    minStakingTime = (60 * 60 * 24), // 1 Day.
    automaticStakeTimeOnMint = (60 * 60 * 24), // 1 Day.
    automaticStakeTimeOnTx = (60 * 60 * 12), // 12 Hours.
}) => {
    const erc721sFactory = await ethers.getContractFactory('MinimalErc721SImpl')

    const deploymentConfig: DeploymentConfigStruct = {
        name,
        symbol,
        minStakingTime,
        automaticStakeTimeOnMint,
        automaticStakeTimeOnTx,
    }

    return await erc721sFactory.deploy(deploymentConfig)
}
