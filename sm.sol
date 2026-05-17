pragma solidity ^0.8.34;
// SPDX-License-Identifier: MIT
contract FoodSupplyChain {
    address public admin;

    // 1. Quản lý phân quyền (Danh sách trắng các ví được phép)
    mapping(address => bool) public isFarm;
    mapping(address => bool) public isInspector;
    mapping(address => bool) public isTransporter;
    mapping(address => bool) public isRetailer;

    // 2. Định nghĩa các trạng thái của lô thực phẩm
    enum STAGE { 
        Init,           // Nông trại tạo lô
        Inspected,      // Đã kiểm định
        Transporting,   // Đang vận chuyển
        AtRetailer,     // Đã đến điểm bán lẻ
        Sold            // Đã bán cho người tiêu dùng
    }

    // 3. Cấu trúc lưu lịch sử từng bước (Cập nhật thời gian, người cập nhật, mã Hash)
    struct HistoryLog {
        STAGE stage;
        address updater;
        uint256 timestamp;
        string dataHash; // Mã băm (CID của IPFS) để kiểm tra dữ liệu off-chain không bị sửa đổi
    }

    // 4. Cấu trúc chính của Lô sản phẩm (Khớp với bảng của bạn)
    struct Batch {
        uint256 batchId;
        string name;
        address creator;
        STAGE currentStage;
        HistoryLog[] history; // Mảng lưu trữ toàn bộ lịch sử các bước
    }

    mapping(uint256 => Batch) public batches;
    uint256 public batchCount = 0;

    // --- CÁC MODIFIER KIỂM TRA QUYỀN ---
    modifier onlyAdmin() { require(msg.sender == admin, "Chi Admin moi co quyen"); _; }
    modifier onlyFarm() { require(isFarm[msg.sender], "Khong phai Nong trai"); _; }
    modifier onlyInspector() { require(isInspector[msg.sender], "Khong phai Kiem dinh"); _; }
    modifier onlyTransporter() { require(isTransporter[msg.sender], "Khong phai Van chuyen"); _; }
    modifier onlyRetailer() { require(isRetailer[msg.sender], "Khong phai Ban le"); _; }

    constructor() {
        admin = msg.sender;
    }

    // --- ADMIN CẤP QUYỀN ---
    function addFarm(address _addr) public onlyAdmin { isFarm[_addr] = true; }
    function addInspector(address _addr) public onlyAdmin { isInspector[_addr] = true; }
    function addTransporter(address _addr) public onlyAdmin { isTransporter[_addr] = true; }
    function addRetailer(address _addr) public onlyAdmin { isRetailer[_addr] = true; }

    // --- QUY TRÌNH CHUỖI CUNG ỨNG ---

    // 1. Nông trại tạo lô hàng
    function createBatch(string memory _name, string memory _dataHash) public onlyFarm {
        batchCount++;
        
        // Tạo lô hàng mới
        Batch storage newBatch = batches[batchCount];
        newBatch.batchId = batchCount;
        newBatch.name = _name;
        newBatch.creator = msg.sender;
        newBatch.currentStage = STAGE.Init;

        // Ghi lại lịch sử bước 1
        newBatch.history.push(HistoryLog({
            stage: STAGE.Init,
            updater: msg.sender,
            timestamp: block.timestamp,
            dataHash: _dataHash
        }));
    }

    // 2. Đơn vị kiểm định xác nhận
    function inspectBatch(uint256 _batchId, string memory _dataHash) public onlyInspector {
        require(batches[_batchId].currentStage == STAGE.Init, "Sai quy trinh");
        
        batches[_batchId].currentStage = STAGE.Inspected;
        batches[_batchId].history.push(HistoryLog(STAGE.Inspected, msg.sender, block.timestamp, _dataHash));
    }

    // 3. Đơn vị vận chuyển nhận hàng
    function transportBatch(uint256 _batchId, string memory _dataHash) public onlyTransporter {
        require(batches[_batchId].currentStage == STAGE.Inspected, "Sai quy trinh");
        
        batches[_batchId].currentStage = STAGE.Transporting;
        batches[_batchId].history.push(HistoryLog(STAGE.Transporting, msg.sender, block.timestamp, _dataHash));
    }

    // 4. Nhà bán lẻ nhận hàng
    function receiveBatch(uint256 _batchId, string memory _dataHash) public onlyRetailer {
        require(batches[_batchId].currentStage == STAGE.Transporting, "Sai quy trinh");
        
        batches[_batchId].currentStage = STAGE.AtRetailer;
        batches[_batchId].history.push(HistoryLog(STAGE.AtRetailer, msg.sender, block.timestamp, _dataHash));
    }

    // --- HÀM TRUY XUẤT CHO NGƯỜI TIÊU DÙNG (QR CODE) ---
    // Trả về toàn bộ lịch sử của một lô hàng
    function getBatchHistory(uint256 _batchId) public view returns (HistoryLog[] memory) {
        return batches[_batchId].history;
    }
}