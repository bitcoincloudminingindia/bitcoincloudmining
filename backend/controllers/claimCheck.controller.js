const claimCheckService = require('../services/claimCheck.service');
const logger = require('../utils/logger');

// Check claim eligibility
exports.checkClaimEligibility = async (req, res) => {
    try {
        const userId = req.user.userId || req.user.id;
        const { transactionId } = req.params;

        logger.info('Checking claim eligibility:', { userId, transactionId });
        const result = await claimCheckService.checkClaimEligibility(userId, transactionId);
        
        res.json({
            success: true,
            data: result
        });
    } catch (error) {
        logger.error('Error in checkClaimEligibility:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Process claim
exports.processClaim = async (req, res) => {
    try {
        const userId = req.user.userId || req.user.id;
        const { transactionId } = req.params;

        logger.info('Processing claim:', { userId, transactionId });
        const result = await claimCheckService.processClaim(userId, transactionId);
        
        res.json({
            success: true,
            message: 'Claim processed successfully',
            data: result
        });
    } catch (error) {
        logger.error('Error in processClaim:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Convert rejected to completed
exports.convertRejectedToCompleted = async (req, res) => {
    try {
        const userId = req.user.userId || req.user.id;
        const { transactionId } = req.params;

        logger.info('Converting rejected to completed:', { userId, transactionId });
        const result = await claimCheckService.convertRejectedToCompleted(userId, transactionId);
        
        res.json({
            success: true,
            message: 'Transaction converted successfully',
            data: result
        });
    } catch (error) {
        logger.error('Error in convertRejectedToCompleted:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Get claim history
exports.getClaimHistory = async (req, res) => {
    try {
        const userId = req.user.userId || req.user.id;

        logger.info('Getting claim history for user:', userId);
        const result = await claimCheckService.getClaimHistory(userId);
        
        res.json({
            success: true,
            data: result
        });
    } catch (error) {
        logger.error('Error in getClaimHistory:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Check claim status
const checkClaimStatus = async (req, res) => {
  try {
    const userId = req.user.id;
    const status = await claimCheckService.checkClaimStatus(userId);
    res.json(status);
  } catch (error) {
    logger.error('Error checking claim status:', error);
    res.status(500).json({ message: 'Error checking claim status' });
  }
};

// Add claim transaction
const addClaimTransaction = async (req, res) => {
  try {
    const userId = req.user.id;
    const { amount } = req.body;

    // Check if user can claim
    const status = await claimCheckService.checkClaimStatus(userId);
    if (!status.canClaim) {
      return res.status(400).json({
        message: 'Cannot claim yet',
        timeUntilNextClaim: status.timeUntilNextClaim
      });
    }

    // Add claim transaction
    const transaction = await claimCheckService.addClaimTransaction(userId, amount);
    res.json(transaction);
  } catch (error) {
    logger.error('Error adding claim transaction:', error);
    res.status(500).json({ message: 'Error adding claim transaction' });
  }
};

module.exports = {
  checkClaimStatus,
  addClaimTransaction
}; 