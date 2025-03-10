// src/app/services/environment.service.ts
import { Injectable } from '@angular/core';
import { TransferState, makeStateKey } from '@angular/core';

// Use the same key as defined in your app.config.server.ts
const envStateKey = makeStateKey<any>('env');

@Injectable({
  providedIn: 'root'
})
export class EnvironmentService {
  private envVars: any;

  constructor(private transferState: TransferState) {
    // Get environment variables from TransferState
    this.envVars = this.transferState.get(envStateKey, {
      // Default values as fallback
      API_URL: 'http://localhost:3000/api',
      // Other default variables
    });
  }

  get apiUrl(): string {
    return this.envVars.API_URL || '';
  }

  // Add other getters for additional environment variables as needed
}
