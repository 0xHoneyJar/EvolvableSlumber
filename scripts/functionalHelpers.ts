import { ethers } from "hardhat";
import { BigNumber } from 'ethers'
import { pipe } from "fp-ts/lib/function";
import { ERC721S, MinimalErc721SImpl } from "../typechain-types";

export const toWei = (x: number) => ethers.utils.parseUnits(x.toString(), 'ether')
export const fromWei = (x: BigNumber) => ethers.utils.formatEther(x)

export const randomAddress = () => `0x${[...Array(40)]
    .map(() => Math.floor(Math.random() * 16).toString(16))
    .join('')}`;

export const getRandomAccount = async () => 
    await ethers.getImpersonatedSigner(randomAddress())

export const getRandomFundedAccount = async (funds: number = 10) => {
    const acc = await getRandomAccount() 
    const [admin, ] = await ethers.getSigners()
    await admin.sendTransaction({to: acc.address, value: toWei(funds)})
    return acc
};

export const sleep = (s: number) => new Promise(resolve => setTimeout(resolve, s*1000)); 

/**
 * @returns A number in the inclsusive range `range` following an
 * exponential distribution of parameter `lambda`.
 */
export const randExpRange = (lambda: number, range: [number, number]) => pipe(
    Math.random(),
    r => - Math.log(1 - r) / lambda + range[0],
    Math.floor,
    n => Math.min(n, range[1])
)

