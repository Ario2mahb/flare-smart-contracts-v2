// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../../contracts/protocol/lib/NodesHistory.sol";

contract NodesHistoryTest is Test {
    using NodesHistory for NodesHistory.CheckPointHistoryState;

    NodesHistory.CheckPointHistoryState checkPointHistoryState;

    NodesHistory.CheckPointHistoryState emptyState;

    NodesHistory.CheckPointHistoryState emptyState2;

    uint32 maxNodeIds = 5;

    function setUp() public {
        for (uint256 j = 1; j < 5; j++) {
            vm.roll(100 * j);

            checkPointHistoryState.addRemoveNodeId(
                bytes20(keccak256(abi.encode(j))),
                true,
                maxNodeIds
            );
        }

        checkPointHistoryState.addRemoveNodeId(
            bytes20(keccak256(abi.encode(3))),
            false,
            maxNodeIds
        );

        checkPointHistoryState.addRemoveNodeId(
            bytes20(keccak256(abi.encode(2))),
            true,
            maxNodeIds
        );
    }

    function test_addNodeInPastFail() public {
        vm.expectRevert();

        vm.roll(10);
        checkPointHistoryState.addRemoveNodeId(
            bytes20(abi.encode("whatever")),
            true,
            maxNodeIds
        );
    }

    function test_nodeIdsAtEmpty() public {
        vm.roll(990);

        bytes20[] memory nodesAt = emptyState.nodeIdsAtNow();
        bytes20[] memory nodesAt70 = emptyState.nodeIdsAt(70);

        (uint256 length, ) = emptyState.nodeIdsAtNowRaw();

        uint256 count = emptyState.countAt(100);

        assertEq(nodesAt.length, 0);
        assertEq(nodesAt70.length, 0);
        assertEq(count, 0);

        assertEq(length, 0);
    }

    function test_NodeIdsAt() public {
        vm.roll(500);

        bytes20[] memory nodesAtNow = checkPointHistoryState.nodeIdsAtNow();
        bytes20[] memory nodesAt101 = checkPointHistoryState.nodeIdsAt(101);

        uint256 count = checkPointHistoryState.countAt(202);

        (
            uint256 length,
            mapping(uint256 => NodesHistory.Node) storage nodeIds
        ) = checkPointHistoryState.nodeIdsAtNowRaw();

        assertEq(nodesAtNow.length, 3);
        assertEq(nodesAt101.length, 1);

        assertEq(nodesAtNow[0], bytes20(keccak256(abi.encode(1))));
        assertEq(nodesAtNow[2], bytes20(keccak256(abi.encode(4))));
        assertEq(count, 2);

        assertEq(length, 3);
        assertEq(nodeIds[0].nodeId, bytes20(keccak256(abi.encode(1))));
    }

    function test_cleanEmpty() public {
        vm.roll(99);

        uint256 cleaned = emptyState.cleanupOldCheckpoints(3, 3);

        assertEq(cleaned, 0);
    }

    function test_addRemoveNodeIdEmptyAdd() public {
        vm.roll(99);

        emptyState2.addRemoveNodeId(
            bytes20(keccak256(abi.encode("whatever"))),
            true,
            maxNodeIds
        );

        assertEq(emptyState2.startIndex, 0);
        assertEq(emptyState2.endIndex, 1);
    }

    function test_addRemoveNodeIdEmptyRemove() public {
        vm.roll(99);

        emptyState2.addRemoveNodeId(
            bytes20(keccak256(abi.encode("whatever"))),
            false,
            maxNodeIds
        );

        assertEq(emptyState2.startIndex, 0);
        assertEq(emptyState2.endIndex, 0);
    }

    function test_addRemoveNodeIdTwice() public {
        vm.roll(700);

        uint64 length = checkPointHistoryState.endIndex;

        checkPointHistoryState.addRemoveNodeId(
            bytes20(keccak256(abi.encode("first"))),
            true,
            maxNodeIds
        );

        checkPointHistoryState.addRemoveNodeId(
            bytes20(keccak256(abi.encode("second"))),
            true,
            maxNodeIds
        );

        assertEq(length + 1, checkPointHistoryState.endIndex);
    }

    function test_clean() public {
        vm.roll(800);

        uint256 cleaned = checkPointHistoryState.cleanupOldCheckpoints(3, 400);
        assertEq(cleaned, 3);
        assertEq(checkPointHistoryState.startIndex, 3);
    }

    function test_clean2() public {
        vm.roll(700);

        uint256 cleaned = checkPointHistoryState.cleanupOldCheckpoints(3, 200);
        assertEq(cleaned, 1);
        assertEq(checkPointHistoryState.startIndex, 1);
    }

    function test_clean3() public {
        vm.roll(120);

        uint256 cleaned = checkPointHistoryState.cleanupOldCheckpoints(0, 10);
        assertEq(cleaned, 0);
        assertEq(checkPointHistoryState.startIndex, 0);
    }

    function test_clean4() public {
        vm.roll(120);

        uint256 cleaned = checkPointHistoryState.cleanupOldCheckpoints(10, 0);
        assertEq(cleaned, 0);
        assertEq(checkPointHistoryState.startIndex, 0);
    }

    function test_cleanAndNodeAt() public {
        vm.roll(300);

        uint256 cleaned = checkPointHistoryState.cleanupOldCheckpoints(3, 200);
        assertEq(cleaned, 1);
        assertEq(checkPointHistoryState.startIndex, 1);

        vm.expectRevert("NodesHistory: reading from cleaned-up block");
        checkPointHistoryState.nodeIdsAt(102);
    }

    // function test_cleanAndAddressAt2() public {
    //     vm.roll(120);

    //     checkPointHistoryState.cleanupOldCheckpoints(11, 10);

    //     (bytes32 at1, bytes32 at2) = checkPointHistoryState.publicKeyAt(10);
    //     assertEq(at1, keccak256(abi.encode(10)));
    //     assertEq(at2, keccak256(abi.encode(20)));
    // }

    // function test_addressAtBeforeFirstSet() public {
    //     vm.roll(120);

    //     emptyState.setPublicKey(
    //         keccak256(abi.encode("new")),
    //         keccak256(abi.encode("key"))
    //     );

    //     (bytes32 at1, bytes32 at2) = emptyState.publicKeyAt(10);
    //     assertEq(at1, bytes32(0));
    //     assertEq(at2, bytes32(0));
    // }
}
