const { formatBTC } = require('../utils/format');
const logger = require('../utils/logger');

/**
 * Middleware to format BTC amounts in the request body
 */
const formatBTCAmounts = (req, res, next) => {
    try {
        if (req.body) {
            // Format main amount fields
            if (req.body.amount) {
                req.body.amount = formatBTC(req.body.amount);
            }
            if (req.body.netAmount) {
                req.body.netAmount = formatBTC(req.body.netAmount);
            }
            if (req.body.balance) {
                req.body.balance = formatBTC(req.body.balance);
            }

            // Format amounts in details
            if (req.body.details) {
                if (req.body.details.balanceBefore) {
                    req.body.details.balanceBefore = formatBTC(req.body.details.balanceBefore);
                }
                if (req.body.details.balanceAfter) {
                    req.body.details.balanceAfter = formatBTC(req.body.details.balanceAfter);
                }
                if (req.body.details.amount) {
                    req.body.details.amount = formatBTC(req.body.details.amount);
                }
            }
        }

        next();
    } catch (error) {
        logger.error('Error formatting BTC amounts:', error);
        next();
    }
};

module.exports = {
    formatBTCAmounts
};