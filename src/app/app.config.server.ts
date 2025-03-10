
import {
  mergeApplicationConfig,
  ApplicationConfig,
  TransferState,
  makeStateKey,
  APP_INITIALIZER,
} from '@angular/core';
import { provideServerRendering } from '@angular/platform-server';
import { appConfig } from './app.config';
import * as dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const envStateKey = makeStateKey<{ data: string }>('env');

/**
 * Read the required environment variables from process.env
 * and set them in the transfer state using defined above key.
 * This function is executed as an app initializer.
*/
export function transferStateFactory(transferState: TransferState) {
  return () => {
    console.log('transferStateFactory');
    const envVars = {
      API_URL: process.env['API_URL'],
      // Add more environment variables as needed
    };
    transferState.set<any>(envStateKey, envVars);
  };
}

const serverConfig: ApplicationConfig = {
  providers: [
    provideServerRendering(),
    {
      provide: APP_INITIALIZER,
      useFactory: transferStateFactory,
      deps: [TransferState],
      multi: true,
    },
  ],
};

export const config = mergeApplicationConfig(appConfig, serverConfig);
