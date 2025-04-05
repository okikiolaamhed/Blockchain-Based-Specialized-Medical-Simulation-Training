import { describe, it, expect, beforeEach } from "vitest"

// Mock implementation for testing Clarity contracts

// Mock data structure
const instructors = new Map()
let certificationAuthority = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
let txSender = certificationAuthority

// Mock contract functions
const mockContract = {
  setCertificationAuthority: (newAuthority) => {
    if (txSender !== certificationAuthority) {
      return { error: "ERR_UNAUTHORIZED" }
    }
    
    certificationAuthority = newAuthority
    return { value: true }
  },
  
  registerInstructor: (instructor, name, specialization, certificationLevel, validForDays, certifications) => {
    if (txSender !== certificationAuthority) {
      return { error: "ERR_UNAUTHORIZED" }
    }
    
    if (instructors.has(instructor)) {
      return { error: "ERR_ALREADY_EXISTS" }
    }
    
    const currentTime = Date.now()
    const expirationDate = currentTime + validForDays * 86400 * 1000
    
    instructors.set(instructor, {
      name,
      specialization,
      "certification-date": currentTime,
      "expiration-date": expirationDate,
      "certification-level": certificationLevel,
      active: true,
      certifications,
    })
    
    return { value: instructor }
  },
  
  renewCertification: (instructor, validForDays) => {
    if (txSender !== certificationAuthority) {
      return { error: "ERR_UNAUTHORIZED" }
    }
    
    if (!instructors.has(instructor)) {
      return { error: "ERR_NOT_FOUND" }
    }
    
    const currentTime = Date.now()
    const newExpirationDate = currentTime + validForDays * 86400 * 1000
    
    const instructorData = instructors.get(instructor)
    instructorData["expiration-date"] = newExpirationDate
    instructorData.active = true
    
    instructors.set(instructor, instructorData)
    
    return { value: true }
  },
  
  deactivateInstructor: (instructor) => {
    if (txSender !== certificationAuthority) {
      return { error: "ERR_UNAUTHORIZED" }
    }
    
    if (!instructors.has(instructor)) {
      return { error: "ERR_NOT_FOUND" }
    }
    
    const instructorData = instructors.get(instructor)
    instructorData.active = false
    
    instructors.set(instructor, instructorData)
    
    return { value: true }
  },
  
  getInstructor: (instructor) => {
    return instructors.get(instructor) || null
  },
  
  isCertified: (instructor) => {
    if (!instructors.has(instructor)) {
      return false
    }
    
    const instructorData = instructors.get(instructor)
    const currentTime = Date.now()
    
    return instructorData.active && instructorData["expiration-date"] > currentTime
  },
}

describe("Instructor Certification Contract", () => {
  beforeEach(() => {
    // Clear mock data before each test
    instructors.clear()
    certificationAuthority = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
    txSender = certificationAuthority
  })
  
  describe("setCertificationAuthority", () => {
    it("should set a new certification authority when called by current authority", () => {
      const newAuthority = "ST2PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
      
      const result = mockContract.setCertificationAuthority(newAuthority)
      
      expect(result).toHaveProperty("value", true)
      expect(certificationAuthority).toBe(newAuthority)
    })
    
    it("should fail when called by non-authority", () => {
      txSender = "ST3PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
      
      const result = mockContract.setCertificationAuthority("ST4PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM")
      
      expect(result).toHaveProperty("error", "ERR_UNAUTHORIZED")
    })
  })
  
  describe("registerInstructor", () => {
    it("should register a new instructor successfully", () => {
      const instructor = "ST2PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
      
      const result = mockContract.registerInstructor(instructor, "Dr. Jane Smith", "Cardiology", 3, 365, [
        "ACLS",
        "BLS",
        "PALS",
      ])
      
      expect(result).toHaveProperty("value", instructor)
      expect(instructors.has(instructor)).toBe(true)
      expect(instructors.get(instructor).name).toBe("Dr. Jane Smith")
    })
    
    it("should fail when registering an instructor that already exists", () => {
      const instructor = "ST2PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
      
      // Register first time
      mockContract.registerInstructor(instructor, "Dr. Jane Smith", "Cardiology", 3, 365, ["ACLS", "BLS", "PALS"])
      
      // Try to register again
      const result = mockContract.registerInstructor(instructor, "Dr. Jane Smith", "Emergency Medicine", 2, 180, [
        "ACLS",
        "BLS",
      ])
      
      expect(result).toHaveProperty("error", "ERR_ALREADY_EXISTS")
    })
  })
  
  describe("isCertified", () => {
    it("should return true for active instructor with valid certification", () => {
      const instructor = "ST2PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
      
      mockContract.registerInstructor(instructor, "Dr. Jane Smith", "Cardiology", 3, 365, ["ACLS", "BLS", "PALS"])
      
      const result = mockContract.isCertified(instructor)
      
      expect(result).toBe(true)
    })
    
    it("should return false for deactivated instructor", () => {
      const instructor = "ST2PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
      
      mockContract.registerInstructor(instructor, "Dr. Jane Smith", "Cardiology", 3, 365, ["ACLS", "BLS", "PALS"])
      
      mockContract.deactivateInstructor(instructor)
      
      const result = mockContract.isCertified(instructor)
      
      expect(result).toBe(false)
    })
  })
})

