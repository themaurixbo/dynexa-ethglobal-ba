// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SponsorDelegationVault.sol";
import "../src/DynexaYieldConfig.sol";
import "../src/DynexaFlareTreasury.sol";
import "../src/DynexaFTSOManager.sol";
import "../src/DynexaSubsidyEngine.sol";

contract DeployAllScript is Script {
    // Direcciones reales en Coston2
    address constant WNAT_COSTON2 = 0xC67DCE33D7A8efA5FfEB961899C73fe01bCe9273;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer:", deployer);
        console.log("========================================");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy SponsorDelegationVault
        SponsorDelegationVault vault = new SponsorDelegationVault(
            WNAT_COSTON2,
            deployer    // dataProvider
        );
        console.log("1. SponsorDelegationVault:", address(vault));

        // 2. Deploy DynexaYieldConfig
        DynexaYieldConfig config = new DynexaYieldConfig(
            deployer,   // admin
            5000,       // maxFtsoAllocationBps (50%)
            4000,       // maxDefiAllocationBps (40%)
            3000        // minLiquidBufferBps (30%)
        );
        console.log("2. DynexaYieldConfig:", address(config));

        // 3. Deploy DynexaFlareTreasury
        DynexaFlareTreasury treasury = new DynexaFlareTreasury(
            address(0x1),       // _flrToken (placeholder)
            address(0x1),       // _fxrpToken (placeholder)
            address(0x1),       // _xrpfVault (placeholder)
            address(config),    // _yieldConfig
            deployer            // admin
        );
        console.log("3. DynexaFlareTreasury:", address(treasury));

        // 4. Deploy DynexaFTSOManager
        DynexaFTSOManager manager = new DynexaFTSOManager(
            address(treasury),  // _treasury
            address(0x1),       // _flrToken (placeholder)
            deployer            // admin
        );
        console.log("4. DynexaFTSOManager:", address(manager));

        // 5. Deploy DynexaSubsidyEngine
        DynexaSubsidyEngine engine = new DynexaSubsidyEngine(
            address(treasury),  // _treasury
            deployer            // admin
        );
        console.log("5. DynexaSubsidyEngine:", address(engine));

        console.log("========================================");
        console.log("All contracts deployed successfully!");

        vm.stopBroadcast();
    }
}
