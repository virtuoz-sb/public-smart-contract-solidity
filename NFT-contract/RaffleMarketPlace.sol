// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import "./interfaces/IRaffleFactory.sol";

error Goobig__NotOwner();
error Goobig__TransferFailed();
error Goobig__InvalidTicketType();
error Goobig__InvalidDuration();
error Goobig__InvalidNFTAddress();
error Goobig__InvalidFee();
error Goobig__NotAvailableRaffle();
error Goobig__InvalidBuyTickets();
error Goobig__NotEnoughBuyTickets();
error Goobig__SendMoreToRegisterRaffle();
error Goobig__InvalidCancel();
error Goobig__InvalidExcute();
error Goobig__InvalidExtension();
error Goobig__UpkeepNotNeeded(
    uint256 totalRaffles,
    uint256 totalActiveRaffles,
    uint256 raffleId
);
error Goobig__NotSeller();

/* Type declarations */
enum RaffleState {
    OPEN,
    PENDING,
    CANCELED,
    CLOSED,
    CANCELING
}

contract RaffleMarketPlace is
    Ownable,
    ERC721Holder,
    VRFConsumerBaseV2,
    KeeperCompatibleInterface
{
    using SafeMath for uint256;

    struct RaffleData {
        address raffleAddress;
        address nftAddress;
        uint256 tokenId;
        uint256 totalTickets;
        uint256 ticketPrice;
        uint256 totalPrice;
        uint256 duration;
        address seller;
        uint256 created;
        uint256 soldTickets;
        RaffleState raffleState;
    }
    /* Fee Variables */
    uint256 public constant MAX_FEE_BY_MILLION = 30000; // 3%
    uint256 public s_feeByMillion;

    /* Chainlnk VRF Variables */
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    mapping(uint256 => uint256) private requestIdToRaffleId;

    /* Raffle Variables */
    uint256 public s_registerFee;
    uint256[3] public NUMBER_OF_TICKETS_BY_TYPE = [10, 100, 1000];
    mapping(uint256 => RaffleData) public s_raffles;

    uint256 public s_totalRaffleCounter;
    address public s_raffleFactoryAddress;
    uint256 public s_pendingPreiod;

    uint private unlocked = 1;

    /* Events */
    event ChangedFee(uint256 feeByMillion);
    event ChangedRegisterFee(uint256 registerFee);
    event ChaingedPendingPeriod(uint256 pendingPeriod);

    event RaffleRegister(uint256 indexed raffleId);

    event SoldTickets(
        uint256 indexed raffleId,
        address indexed buyer,
        uint256 indexed tickets
    );

    event RequestedRaffleWinner(
        uint256 indexed raffleId,
        uint256 indexed requestId
    );

    event WinnerPicked(uint256 indexed raffleId, uint256 indexed winnerTicket);

    event SoldNFT(
        uint256 indexed raffleId,
        address indexed from,
        address indexed to,
        address nftAddress,
        uint256 tokenId
    );

    event ExcuteRaffle(uint256 indexed raffleId);
    event CancelRaffle(uint256 indexed raffleId);
    event CancelingRaffle(uint256 indexed raffleId);
    event ExtendRaffle(uint256 indexed raffleId, uint256 exPeriod);

    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint32 callbackGasLimit,
        address raffleFactoryAddress,
        uint256 pendingPreiod
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_registerFee = 1e16; // for Only Test
        s_totalRaffleCounter = 0;
        s_feeByMillion = 30000; // 3%
        s_raffleFactoryAddress = raffleFactoryAddress;
        s_pendingPreiod = pendingPreiod;
    }

    modifier lock() {
        require(unlocked == 1, "Goobig: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function setFeeByMillion(uint256 feeByMillion) external lock onlyOwner {
        if (feeByMillion > MAX_FEE_BY_MILLION) {
            revert Goobig__InvalidFee();
        }
        s_feeByMillion = feeByMillion;
        emit ChangedFee(s_feeByMillion);
    }

    function setRegisterFee(uint256 registerFee) external lock onlyOwner {
        s_registerFee = registerFee;
        emit ChangedRegisterFee(registerFee);
    }

    function setPendingPeriod(uint256 pendingPeriod) external lock onlyOwner {
        s_pendingPreiod = pendingPeriod;
        emit ChaingedPendingPeriod(pendingPeriod);
    }

    function registerRaffle(
        address nftAddress,
        uint256 tokenId,
        uint256 ticketType,
        uint256 ticketPrice,
        uint256 duration
    ) external payable lock {
        if (msg.value < s_registerFee) {
            revert Goobig__SendMoreToRegisterRaffle();
        }
        IERC721 nftCollection = IERC721(nftAddress);
        address assetOwner = nftCollection.ownerOf(tokenId);

        if (assetOwner != msg.sender) {
            revert Goobig__NotOwner();
        }
        if (ticketType > 2 || ticketType < 0) {
            revert Goobig__InvalidTicketType();
        }
        if (duration < 3600) {
            revert Goobig__InvalidDuration();
        }

        nftCollection.safeTransferFrom(assetOwner, address(this), tokenId);

        // send ETH to owner
        address payable feeAcount = payable(owner());
        (bool success, ) = feeAcount.call{value: msg.value}("");
        if (!success) {
            revert Goobig__TransferFailed();
        }
        {
            uint256 totalTickets = NUMBER_OF_TICKETS_BY_TYPE[ticketType];
            IRaffleFactory raffleFactory = IRaffleFactory(
                s_raffleFactoryAddress
            );
            address raffleAddress = raffleFactory.createRaffle(
                nftAddress,
                tokenId
            );
            RaffleData memory raffle = RaffleData({
                raffleAddress: raffleAddress,
                nftAddress: nftAddress,
                tokenId: tokenId,
                totalTickets: totalTickets,
                ticketPrice: ticketPrice,
                totalPrice: ticketPrice.mul(totalTickets),
                duration: duration,
                seller: msg.sender,
                created: block.timestamp,
                soldTickets: 0,
                raffleState: RaffleState.OPEN
            });
            uint256 totalRaffleCounter = s_totalRaffleCounter;
            s_raffles[totalRaffleCounter] = raffle;
            s_totalRaffleCounter = totalRaffleCounter + 1;
            emit RaffleRegister(totalRaffleCounter);
        }
    }

    function buyTickets(uint256 raffleId, uint256 tickets) public payable lock {
        if (raffleId >= s_totalRaffleCounter) {
            revert Goobig__NotAvailableRaffle();
        }
        RaffleData storage raffle = s_raffles[raffleId];
        if (
            raffle.created + raffle.duration + s_pendingPreiod < block.timestamp
        ) {
            revert Goobig__NotAvailableRaffle();
        }
        uint256 soldTickets = raffle.soldTickets;
        address raffleAddress = raffle.raffleAddress;
        uint256 ticketPrice = raffle.ticketPrice;
        uint256 totalTickets = raffle.totalTickets;

        if (tickets == 0) {
            revert Goobig__InvalidBuyTickets();
        }
        if (soldTickets + tickets > totalTickets) {
            revert Goobig__InvalidBuyTickets();
        }
        if (msg.value < ticketPrice.mul(tickets)) {
            revert Goobig__NotEnoughBuyTickets();
        }
        IRaffleFactory raffleFactory = IRaffleFactory(s_raffleFactoryAddress);
        raffleFactory.buyRaffleTickets(raffleAddress, msg.sender, tickets);
        raffle.soldTickets = soldTickets + tickets;
        emit SoldTickets(raffleId, msg.sender, tickets);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        bool _upkeepNeeded = false;
        uint256 raffleId = 0;
        for (uint256 i = 0; i < s_totalRaffleCounter; i++) {
            RaffleData memory raffle = s_raffles[i];
            if (raffle.raffleState == RaffleState.OPEN) {
                /* check if all tickets was sold in every open raffles */
                if (raffle.soldTickets == raffle.totalTickets) {
                    _upkeepNeeded = true;
                    raffleId = i;
                    break;
                }
                /* check if time is over in every open raffles */
                if (raffle.created + raffle.duration < block.timestamp) {
                    _upkeepNeeded = true;
                    raffleId = i;
                    break;
                }
            } else if (raffle.raffleState == RaffleState.PENDING) {
                /* check the pending period */
                if (
                    raffle.created + raffle.duration + s_pendingPreiod <
                    block.timestamp
                ) {
                    _upkeepNeeded = true;
                    raffleId = i;
                    break;
                }
            }
        }
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = _upkeepNeeded && hasBalance;
        performData = abi.encode(raffleId);
        return (upkeepNeeded, performData);
    }

    /**
     * Once `checkUpkeep` is returning `true`, this function is called and Chainlink VRF call to get a random winner.
     */
    function performUpkeep(bytes calldata performData) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (upkeepNeeded) {
            uint256 raffleId = abi.decode(performData, (uint256));
            RaffleData storage raffle = s_raffles[raffleId];
            if (raffle.raffleState == RaffleState.OPEN) {
                if (raffle.soldTickets == raffle.totalTickets) {
                    /* if all tickets was sold in every active raffles */
                    sellNft(raffleId);
                } else if (raffle.created + raffle.duration < block.timestamp) {
                    /* if time is over, set it as pending */
                    raffle.raffleState = RaffleState.PENDING;
                }
            } else if (raffle.raffleState == RaffleState.PENDING) {
                if (
                    raffle.created + raffle.duration + s_pendingPreiod <
                    block.timestamp
                ) {
                    if (raffle.soldTickets > 0) {
                        sellNft(raffleId);
                    } else {
                        refundNFT(raffleId);
                    }
                }
            }
        }
    }

    function sellNft(uint256 raffleId) internal {
        RaffleData storage raffle = s_raffles[raffleId];
        raffle.raffleState = RaffleState.CLOSED; // closed
        /** process choose the winner */
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        requestIdToRaffleId[requestId] = raffleId;
        emit RequestedRaffleWinner(raffleId, requestId);
    }

    function excuteRaffle(uint256 raffleId) external lock {
        RaffleData memory raffle = s_raffles[raffleId];
        if (msg.sender != raffle.seller) {
            revert Goobig__NotSeller();
        }
        if (raffle.raffleState != RaffleState.PENDING) {
            revert Goobig__InvalidExcute();
        }
        if (raffle.soldTickets == 0) {
            revert Goobig__InvalidExcute();
        }
        sellNft(raffleId);
        emit ExcuteRaffle(raffleId);
    }

    function refundNFT(uint256 raffleId) internal {
        RaffleData storage raffle = s_raffles[raffleId];
        raffle.raffleState = RaffleState.CANCELED;
        IERC721 nftContract = IERC721(raffle.nftAddress);
        nftContract.transferFrom(address(this), raffle.seller, raffle.tokenId);
        emit CancelRaffle(raffleId);
    }

    function cancelRaffle(uint256 raffleId) external lock {
        RaffleData storage raffle = s_raffles[raffleId];
        if (msg.sender != raffle.seller) {
            revert Goobig__NotSeller();
        }
        if (
            raffle.raffleState != RaffleState.PENDING &&
            raffle.raffleState != RaffleState.CANCELING
        ) {
            revert Goobig__InvalidCancel();
        }
        uint256 from = 0;
        uint256 to = 0;
        if (raffle.soldTickets > 0) {
            if (raffle.soldTickets > 500) {
                if (raffle.raffleState == RaffleState.PENDING) {
                    to = 500;
                } else if (raffle.raffleState == RaffleState.CANCELING) {
                    from = 500;
                    to = raffle.soldTickets;
                }
            } else {
                to = raffle.soldTickets;
            }
            /** Refund all ETH paid for buying tickets */
            IRaffleFactory raffleFactory = IRaffleFactory(s_raffleFactoryAddress);
            for (uint256 i = from; i < to; i++) {
                address payable buyer = payable(
                    raffleFactory.ownerOfTicket(raffle.raffleAddress, i)
                );
                (bool success, ) = buyer.call{value: raffle.ticketPrice}("");
                if (!success) {
                    revert Goobig__TransferFailed();
                }
            }

        }
        if (to == 500) {
            raffle.raffleState = RaffleState.CANCELING;
            emit CancelingRaffle(raffleId);
        } else {
            IERC721 nftContract = IERC721(raffle.nftAddress);
            raffle.raffleState = RaffleState.CANCELED;
            nftContract.transferFrom(address(this), raffle.seller, raffle.tokenId);
            emit CancelRaffle(raffleId);
        }
    }

    function extendRaffle(uint256 raffleId, uint256 exPeriod) external lock {
        RaffleData storage raffle = s_raffles[raffleId];
        if (msg.sender != raffle.seller) {
            revert Goobig__NotSeller();
        }
        if (raffle.raffleState != RaffleState.PENDING) {
            revert Goobig__InvalidExtension();
        }
        raffle.raffleState = RaffleState.OPEN;
        raffle.duration = raffle.duration + exPeriod;
        emit ExtendRaffle(raffleId, exPeriod);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 raffleId = requestIdToRaffleId[requestId];
        RaffleData memory raffle = s_raffles[raffleId];
        uint256 winnerTicket = randomWords[0] % raffle.soldTickets;
        address payable seller = payable(raffle.seller);
        IRaffleFactory raffleFactory = IRaffleFactory(s_raffleFactoryAddress);
        address winner = raffleFactory.ownerOfTicket(
            raffle.raffleAddress,
            winnerTicket
        );
        /** Fee management */
        // send NFT to winner;
        IERC721 nftContract = IERC721(raffle.nftAddress);
        nftContract.transferFrom(address(this), winner, raffle.tokenId);
        // send ETH to seller
        uint256 cost = raffle.ticketPrice.mul(raffle.soldTickets);
        uint256 fee = cost.mul(s_feeByMillion).div(1000000);
        (bool success1, ) = seller.call{value: cost.sub(fee)}("");
        if (!success1) {
            revert Goobig__TransferFailed();
        }
        // send ETH to owner
        address payable feeAcount = payable(owner());
        (bool success2, ) = feeAcount.call{value: fee}("");
        if (!success2) {
            revert Goobig__TransferFailed();
        }

        emit WinnerPicked(raffleId, winnerTicket);
        emit SoldNFT(
            raffleId,
            seller,
            winner,
            raffle.nftAddress,
            raffle.tokenId
        );
    }

    /** get functions */
    function getRaffles() public view returns (RaffleData[] memory raffles) {
        raffles = new RaffleData[](s_totalRaffleCounter);
        for (uint256 i = 0; i < s_totalRaffleCounter; i++) {
            raffles[i] = s_raffles[i];
        }
        return raffles;
    }
}
