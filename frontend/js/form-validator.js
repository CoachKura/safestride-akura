/* =============================================================================
   AKURA FORM-VALIDATOR.JS - Real-Time Form Validation
   ============================================================================= */

class FormValidator {
  constructor(formElement) {
    this.form = formElement;
    this.validationRules = this.getValidationRules();
    this.errors = new Map();
    this.attachEventListeners();
  }

  /**
   * Define validation rules for all fields
   */
  getValidationRules() {
    return {
      // Personal Profile
      firstName: { required: true, minLength: 2, maxLength: 50 },
      lastName: { required: true, minLength: 2, maxLength: 50 },
      email: { required: true, pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/ },
      age: { required: true, min: 18, max: 120, type: 'number' },
      gender: { required: true },
      weight: { required: true, min: 30, max: 200, type: 'number' },
      height: { required: true, min: 100, max: 250, type: 'number' },

      // Medical History
      injuries: { required: false },
      injuryDetails: {
        conditionalRequired: () => this.getFieldValue('injuries') === 'yes'
      },
      medications: { required: false },

      // Body Measurements
      qAngleLeft: { min: 0, max: 40, type: 'number' },
      qAngleRight: { min: 0, max: 40, type: 'number' },
      navicularDrop: { min: 0, max: 30, type: 'number' },
      bodyType: { required: false },

      // ROM Measurements
      ankleFlexibility: { min: 0, max: 45, type: 'number' },
      hipFlexibility: { min: -20, max: 50, type: 'number' },
      cervicalRom: { min: 0, max: 90, type: 'number' },
      shoulderRom: { min: 0, max: 180, type: 'number' },
      kneeRom: { min: 0, max: 150, type: 'number' },

      // FMS Scores
      fmsDeepSquat: { required: false, min: 0, max: 3 },
      fmsHurdleStep: { required: false, min: 0, max: 3 },
      fmsShoulderMobility: { required: false, min: 0, max: 3 },
      fmsActiveLegRaise: { required: false, min: 0, max: 3 },
      fmsPushup: { required: false, min: 0, max: 3 },
      fmsRotaryStability: { required: false, min: 0, max: 3 },
      fmsLunge: { required: false, min: 0, max: 3 },

      // Strength Tests
      plankTime: { min: 0, max: 300, type: 'number' },
      singleLegBalance: { min: 0, max: 120, type: 'number' },
      squats: { min: 0, max: 200, type: 'number' },

      // Flexibility
      sitAndReach: { min: -30, max: 50, type: 'number' },
      painLevel: { min: 0, max: 10, type: 'number' },

      // Running Baseline
      raceTime5K: { pattern: /^(\d{1,2}):(\d{2})(:(\d{2}))?$/ },
      weeklyKm: { required: true, min: 0, max: 150, type: 'number' },
      runningYears: { min: 0, max: 60, type: 'number' }
    };
  }

  /**
   * Attach event listeners to all form fields
   */
  attachEventListeners() {
    if (!this.form) return;

    // Real-time validation on blur
    this.form.querySelectorAll('input, select, textarea').forEach(field => {
      field.addEventListener('blur', (e) => this.validateField(e.target));
      field.addEventListener('input', (e) => {
        if (field.classList.contains('invalid')) {
          this.validateField(e.target);
        }
      });
    });
  }

  /**
   * Validate individual field
   */
  validateField(fieldElement) {
    const fieldName = fieldElement.name || fieldElement.id;
    const rules = this.validationRules[fieldName];
    const value = fieldElement.value.trim();

    // If no rules defined, field is valid
    if (!rules) {
      this.clearError(fieldElement);
      return { valid: true };
    }

    // Run validation rules
    let error = this.checkRequired(fieldName, value, rules);
    if (!error && value) {
      error = this.checkType(value, rules);
    }
    if (!error && value) {
      error = this.checkMinMax(value, rules);
    }
    if (!error && value) {
      error = this.checkPattern(value, rules);
    }
    if (!error && value) {
      error = this.checkMinMaxLength(value, rules);
    }

    if (error) {
      this.showValidationError(fieldElement, error);
      return { valid: false, error };
    } else {
      this.showValidationSuccess(fieldElement);
      return { valid: true };
    }
  }

  /**
   * Check if field is required
   */
  checkRequired(fieldName, value, rules) {
    if (rules.required && !value) {
      return `${this.formatFieldName(fieldName)} is required`;
    }

    if (rules.conditionalRequired && rules.conditionalRequired()) {
      if (!value) {
        return `${this.formatFieldName(fieldName)} is required`;
      }
    }

    return null;
  }

  /**
   * Check field type (number, email, etc.)
   */
  checkType(value, rules) {
    if (rules.type === 'number' && isNaN(parseFloat(value))) {
      return 'Must be a valid number';
    }
    if (rules.type === 'email' && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
      return 'Must be a valid email address';
    }
    return null;
  }

  /**
   * Check min/max constraints
   */
  checkMinMax(value, rules) {
    const numValue = parseFloat(value);

    if (rules.min !== undefined && numValue < rules.min) {
      return `Must be at least ${rules.min}`;
    }
    if (rules.max !== undefined && numValue > rules.max) {
      return `Cannot exceed ${rules.max}`;
    }

    return null;
  }

  /**
   * Check regex pattern
   */
  checkPattern(value, rules) {
    if (rules.pattern && !rules.pattern.test(value)) {
      return 'Invalid format';
    }
    return null;
  }

  /**
   * Check min/max length for strings
   */
  checkMinMaxLength(value, rules) {
    if (rules.minLength && value.length < rules.minLength) {
      return `Must be at least ${rules.minLength} characters`;
    }
    if (rules.maxLength && value.length > rules.maxLength) {
      return `Cannot exceed ${rules.maxLength} characters`;
    }
    return null;
  }

  /**
   * Show validation error
   */
  showValidationError(fieldElement, message) {
    fieldElement.classList.remove('valid');
    fieldElement.classList.add('invalid');

    // Find or create error message container
    let errorContainer = fieldElement.nextElementSibling;
    if (!errorContainer || !errorContainer.classList.contains('validation-message')) {
      errorContainer = document.createElement('div');
      errorContainer.className = 'validation-message';
      fieldElement.parentNode.insertBefore(errorContainer, fieldElement.nextSibling);
    }

    errorContainer.textContent = message;
    errorContainer.classList.remove('success', 'warning');

    this.errors.set(fieldElement.name || fieldElement.id, message);
  }

  /**
   * Show validation success
   */
  showValidationSuccess(fieldElement) {
    fieldElement.classList.remove('invalid');
    fieldElement.classList.add('valid');

    // Update or hide error message
    let errorContainer = fieldElement.nextElementSibling;
    if (errorContainer && errorContainer.classList.contains('validation-message')) {
      errorContainer.textContent = '';
      errorContainer.classList.remove('invalid');
    }

    this.errors.delete(fieldElement.name || fieldElement.id);
  }

  /**
   * Clear validation styling
   */
  clearError(fieldElement) {
    fieldElement.classList.remove('valid', 'invalid');

    let errorContainer = fieldElement.nextElementSibling;
    if (errorContainer && errorContainer.classList.contains('validation-message')) {
      errorContainer.textContent = '';
    }

    this.errors.delete(fieldElement.name || fieldElement.id);
  }

  /**
   * Validate entire step/form
   */
  validateStep(stepElement) {
    if (!stepElement) return { allValid: true, errors: [] };

    const fields = stepElement.querySelectorAll('input, select, textarea');
    let allValid = true;
    const errors = [];

    fields.forEach(field => {
      const result = this.validateField(field);
      if (!result.valid) {
        allValid = false;
        errors.push({
          field: field.name || field.id,
          message: result.error
        });
      }
    });

    return { allValid, errors };
  }

  /**
   * Get all form data as object
   */
  getFormData() {
    const formData = new FormData(this.form);
    const data = {};

    for (let [key, value] of formData.entries()) {
      if (data[key]) {
        // Handle multiple values (checkboxes)
        if (!Array.isArray(data[key])) {
          data[key] = [data[key]];
        }
        data[key].push(value);
      } else {
        data[key] = value;
      }
    }

    return data;
  }

  /**
   * Get field value by name/id
   */
  getFieldValue(fieldName) {
    const field = this.form.querySelector(`[name="${fieldName}"], #${fieldName}`);
    return field ? field.value : '';
  }

  /**
   * Format field name for display (snake_case to Title Case)
   */
  formatFieldName(fieldName) {
    return fieldName
      .replace(/([A-Z])/g, ' $1')
      .replace(/(_)/g, ' ')
      .split(' ')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ')
      .trim();
  }

  /**
   * Check if entire form is valid
   */
  isFormValid() {
    return this.errors.size === 0;
  }

  /**
   * Get all errors
   */
  getAllErrors() {
    return Array.from(this.errors.entries()).map(([field, message]) => ({
      field,
      message
    }));
  }

  /**
   * Reset form validation
   */
  reset() {
    this.form.querySelectorAll('input, select, textarea').forEach(field => {
      this.clearError(field);
    });
    this.errors.clear();
    this.form.reset();
  }
}

// Export for use
if (typeof module !== 'undefined' && module.exports) {
  module.exports = FormValidator;
}
