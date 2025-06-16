const { body, validationResult } = require('express-validator');

exports.validateRequest = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array()
    });
  }
  next();
};

exports.validateProfileUpdate = [
  body('fullName')
    .optional()
    .trim()
    .isLength({ min: 2 })
    .withMessage('Full name must be at least 2 characters long'),
  
  body('userPhone')
    .optional()
    .trim()
    .matches(/^\+?[1-9]\d{1,14}$/)
    .withMessage('Invalid phone number format'),
  
  body('userDob')
    .optional()
    .isISO8601()
    .withMessage('Invalid date format'),
  
  body('country')
    .optional()
    .trim()
    .isLength({ min: 2 })
    .withMessage('Country must be at least 2 characters long'),
  
  body('profilePicture')
    .optional()
    .isURL()
    .withMessage('Invalid profile picture URL')
]; 