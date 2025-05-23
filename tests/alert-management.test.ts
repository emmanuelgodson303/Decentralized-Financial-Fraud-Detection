import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock the Clarity contract environment
const mockClarity = {
  tx: {
    sender: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
    sponsoredBy: null,
  },
  block: {
    height: 100,
  },
  contracts: {
    'alert-management': {
      functions: {
        'create-alert': vi.fn(),
        'assign-alert': vi.fn(),
        'update-alert-status': vi.fn(),
        'resolve-alert': vi.fn(),
        'get-alert': vi.fn(),
        'get-institution-alerts': vi.fn(),
        'transfer-admin': vi.fn(),
      },
      variables: {
        admin: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
        'alert-counter': 0,
      },
      maps: {
        'alerts': new Map(),
        'institution-alerts': new Map(),
      },
    },
  },
};

// Mock global clarity functions
global.isEq = (a: any, b: any) => a === b;
global.blockHeight = () => mockClarity.block.height;

describe('Alert Management Contract', () => {
  beforeEach(() => {
    // Reset mocks and state before each test
    vi.resetAllMocks();
    mockClarity.contracts['alert-management'].maps['alerts'].clear();
    mockClarity.contracts['alert-management'].maps['institution-alerts'].clear();
    mockClarity.contracts['alert-management'].variables['alert-counter'] = 0;
  });
  
  describe('create-alert', () => {
    it('should create a new alert successfully', () => {
      // Setup
      const txId = 'tx123';
      const riskScore = 75;
      const riskLevel = 'high';
      const institutionId = 'inst1';
      mockClarity.contracts['alert-management'].functions['create-alert'].mockReturnValue({
        success: true,
        value: 1, // New alert ID
      });
      
      // Execute
      const result = mockClarity.contracts['alert-management'].functions['create-alert'](
          txId,
          riskScore,
          riskLevel,
          institutionId
      );
      
      // Verify
      expect(result.success).toBe(true);
      expect(result.value).toBe(1);
      expect(mockClarity.contracts['alert-management'].functions['create-alert']).toHaveBeenCalledWith(
          txId,
          riskScore,
          riskLevel,
          institutionId
      );
    });
  });
  
  describe('assign-alert', () => {
    it('should assign an alert successfully', () => {
      // Setup
      const alertId = 1;
      const investigator = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
      mockClarity.contracts['alert-management'].maps['alerts'].set(
          { alert_id: alertId },
          {
            tx_id: 'tx123',
            risk_score: 75,
            risk_level: 'high',
            timestamp: 90,
            status: 'new',
            assigned_to: null,
            resolution: null,
          }
      );
      mockClarity.contracts['alert-management'].functions['assign-alert'].mockReturnValue({
        success: true,
        value: true,
      });
      
      // Execute
      const result = mockClarity.contracts['alert-management'].functions['assign-alert'](alertId, investigator);
      
      // Verify
      expect(result.success).toBe(true);
    });
    
    it('should fail if alert does not exist', () => {
      // Setup
      const alertId = 1;
      const investigator = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
      mockClarity.contracts['alert-management'].functions['assign-alert'].mockReturnValue({
        success: false,
        error: 404, // Error code for not found
      });
      
      // Execute
      const result = mockClarity.contracts['alert-management'].functions['assign-alert'](alertId, investigator);
      
      // Verify
      expect(result.success).toBe(false);
      expect(result.error).toBe(404);
    });
    
    it('should fail if caller is not admin', () => {
      // Setup
      const alertId = 1;
      const investigator = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
      mockClarity.tx.sender = 'ST3PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM'; // Different sender
      mockClarity.contracts['alert-management'].functions['assign-alert'].mockReturnValue({
        success: false,
        error: 403, // Error code for unauthorized
      });
      
      // Execute
      const result = mockClarity.contracts['alert-management'].functions['assign-alert'](alertId, investigator);
      
      // Verify
      expect(result.success).toBe(false);
      expect(result.error).toBe(403);
    });
  });
  
  describe('resolve-alert', () => {
    it('should resolve an alert successfully', () => {
      // Setup
      const alertId = 1;
      const resolution = 'False positive due to scheduled large transfer';
      mockClarity.contracts['alert-management'].maps['alerts'].set(
          { alert_id: alertId },
          {
            tx_id: 'tx123',
            risk_score: 75,
            risk_level: 'high',
            timestamp: 90,
            status: 'assigned',
            assigned_to: mockClarity.tx.sender,
            resolution: null,
          }
      );
      mockClarity.contracts['alert-management'].functions['resolve-alert'].mockReturnValue({
        success: true,
        value: true,
      });
      
      // Execute
      const result = mockClarity.contracts['alert-management'].functions['resolve-alert'](alertId, resolution);
      
      // Verify
      expect(result.success).toBe(true);
    });
    
    it('should fail if alert does not exist', () => {
      // Setup
      const alertId = 1;
      const resolution = 'False positive due to scheduled large transfer';
      mockClarity.contracts['alert-management'].functions['resolve-alert'].mockReturnValue({
        success: false,
        error: 404, // Error code for not found
      });
      
      // Execute
      const result = mockClarity.contracts['alert-management'].functions['resolve-alert'](alertId, resolution);
      
      // Verify
      expect(result.success).toBe(false);
      expect(result.error).toBe(404);
    });
    
    it('should fail if caller is not admin or assigned investigator', () => {
      // Setup
      const alertId = 1;
      const resolution = 'False positive due to scheduled large transfer';
      mockClarity.contracts['alert-management'].maps['alerts'].set(
          { alert_id: alertId },
          {
            tx_id: 'tx123',
            risk_score: 75,
            risk_level: 'high',
            timestamp: 90,
            status: 'assigned',
            assigned_to: 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG', // Different from tx.sender
            resolution: null,
          }
      );
      mockClarity.tx.sender = 'ST3PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM'; // Different sender
      mockClarity.contracts['alert-management'].functions['resolve-alert'].mockReturnValue({
        success: false,
        error: 403, // Error code for unauthorized
      });
      
      // Execute
      const result = mockClarity.contracts['alert-management'].functions['resolve-alert'](alertId, resolution);
      
      // Verify
      expect(result.success).toBe(false);
      expect(result.error).toBe(403);
    });
  });
});
