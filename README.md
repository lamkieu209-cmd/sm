emit DataHashUpdated(_batchId, _newDataHash);
        emit SignatureVerified(_batchId, signer);
    }

    // ====================== CHUYỂN QUYỀN SỞ HỮU ======================
    function transferOwnership(
        string memory _batchId,
        address _newOwner,
        bytes32 _newDataHash,
        string memory _note
    ) external batchExistsModifier(_batchId) {
        Batch storage batch = batches[_batchId];
        require(batch.currentOwner == msg.sender, "Not current owner");

        address previousOwner = batch.currentOwner;
        batch.currentOwner = _newOwner;
        batch.dataHash = _newDataHash;
        batch.updateTimestamps.push(block.timestamp);
        batch.updatedBy.push(msg.sender);
        batch.updateNotes.push(_note);

        emit OwnershipTransferred(_batchId, previousOwner, _newOwner);
    }

    // ====================== IOT - MÔI TRƯỜNG ======================
    function logEnvironmentData(
        string memory _batchId,
        int256 _temperature,
        uint256 _humidity,
        string memory _note
    ) external onlyValidRole(TRANSPORTER_ROLE) batchExistsModifier(_batchId) {
        Batch storage batch = batches[_batchId];
        require(batch.status == BatchStatus.InTransit, "Only during InTransit");

        environmentLogs[_batchId].push(EnvironmentLog({
            timestamp: block.timestamp,
            temperature: _temperature,
            humidity: _humidity,
            recordedBy: msg.sender
        }));

        emit EnvironmentDataLogged(_batchId, _temperature, _humidity, msg.sender);
    }

    // ====================== RECALL ======================
    function recallBatch(
        string memory _batchId,
        string memory _reason
    ) external onlyRole(ADMIN_ROLE) batchExistsModifier(_batchId) {
        Batch storage batch = batches[_batchId];
        BatchStatus oldStatus = batch.status;
        batch.status = BatchStatus.Recalled;

        emit BatchRecalled(_batchId, _reason, msg.sender);
        emit StatusUpdated(_batchId, oldStatus, BatchStatus.Recalled, msg.sender, _reason);
    }

    // ====================== VIEW FUNCTIONS ======================
    function getBatch(string memory _batchId) external view returns (Batch memory) {
        require(batchExists[_batchId], "Batch does not exist");
        return batches[_batchId];
    }

    function getEnvironmentLogs(string memory _batchId) external view returns (EnvironmentLog[] memory) {
        return environmentLogs[_batchId];
    }

    function getCurrentOwner(string memory _batchId) external view returns (address) {
        return batches[_batchId].currentOwner;
    }
}
