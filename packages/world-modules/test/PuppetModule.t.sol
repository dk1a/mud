// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Test } from "forge-std/Test.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";

import { World } from "@latticexyz/world/src/World.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { IWorldErrors } from "@latticexyz/world/src/IWorldErrors.sol";
import { IDelegationControl } from "@latticexyz/world/src/IDelegationControl.sol";

import { createWorld } from "@latticexyz/world/test/createWorld.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { PuppetModule } from "../src/modules/puppet/PuppetModule.sol";
import { PuppetDelegationControl } from "../src/modules/puppet/PuppetDelegationControl.sol";
import { Puppet } from "../src/modules/puppet/Puppet.sol";
import { PuppetMaster } from "../src/modules/puppet/PuppetMaster.sol";
import { PUPPET_DELEGATION } from "../src/modules/puppet/constants.sol";
import { createPuppet } from "../src/modules/puppet/createPuppet.sol";

import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { PuppetRegistry } from "../src/modules/puppet/tables/PuppetRegistry.sol";
import { PUPPET_TABLE_ID } from "../src/modules/puppet/constants.sol";

contract PuppetTestSystem is System, PuppetMaster {
  event Hello(string message);

  function echoAndEmit(string memory message) public returns (string memory) {
    puppet().log(Hello.selector, abi.encode(message));
    return message;
  }

  function msgSender() public view returns (address) {
    return _msgSender();
  }
}

contract PuppetModuleTest is Test, GasReporter {
  using WorldResourceIdInstance for ResourceId;

  event Hello(string msg);

  IBaseWorld private world;
  IBaseWorld private world2;
  ResourceId private systemId =
    WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: "namespace", name: "testSystem" });
  PuppetTestSystem private puppet;

  address world2Owner = address(bytes20(keccak256("world2Owner")));

  function setUp() public {
    world = createWorld();

    vm.startPrank(world2Owner);
    world2 = createWorld();
    vm.stopPrank();
  }

  function _setupPuppet() internal {
    world.installModule(new PuppetModule(), new bytes(0));

    // Register a new namespace and system
    world.registerNamespace(systemId.getNamespaceId());
    PuppetTestSystem system = new PuppetTestSystem();
    world.registerSystem(systemId, system, true);

    // Connect the puppet
    puppet = PuppetTestSystem(createPuppet(world, systemId));

    // Setup the malicious puppet master on an unrelated world
    StoreSwitch.setStoreAddress(address(world2));
    vm.startPrank(world2Owner);

    PuppetModule module2 = new PuppetModule();
    world2.installRootModule(module2, new bytes(0));
    world2.registerNamespace(systemId.getNamespaceId());
    world2.registerSystem(systemId, system, true);

    PuppetRegistry.set(PUPPET_TABLE_ID, systemId, address(puppet));

    vm.stopPrank();
    StoreSwitch.setStoreAddress(address(0));
  }

  function _setupRootPuppet() internal {
    world.installRootModule(new PuppetModule(), new bytes(0));

    // Register a new system
    world.registerNamespace(systemId.getNamespaceId());
    PuppetTestSystem system = new PuppetTestSystem();
    world.registerSystem(systemId, system, true);

    // Connect the puppet
    puppet = PuppetTestSystem(createPuppet(world, systemId));
  }

  function testEmitOnPuppet() public {
    _setupPuppet();

    vm.expectEmit(true, true, true, true, address(puppet));
    emit Hello("hello world");
    string memory result = puppet.echoAndEmit("hello world");
    assertEq(result, "hello world");

    // Note that the event is emitted on the same puppet from different worlds with respectively different owners
    vm.startPrank(world2Owner);
    vm.expectEmit(true, true, true, true, address(puppet));
    emit Hello("malicious event");
    bytes memory returnData = world2.call(systemId, abi.encodeCall(PuppetTestSystem.echoAndEmit, ("malicious event")));
    assertEq(abi.decode(returnData, (string)), "malicious event");
    vm.stopPrank();
  }

  function testMsgSender() public {
    _setupPuppet();

    assertEq(puppet.msgSender(), address(this));
  }

  function testEmitOnRootPuppet() public {
    _setupRootPuppet();

    vm.expectEmit(true, true, true, true);
    emit Hello("hello world");
    string memory result = puppet.echoAndEmit("hello world");
    assertEq(result, "hello world");
  }

  function testMsgSenderRootPuppet() public {
    _setupRootPuppet();

    assertEq(puppet.msgSender(), address(this));
  }
}
