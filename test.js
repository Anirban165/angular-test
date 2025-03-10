const farmworkConfig = {
    vite: {
      installCommand: 'npm install',
      buildCommand: 'npm run build',
      buildDirectory: 'dist',
      env: {},
      requiredDependencies: ['vite'],
      requiredFiles: ['vite.config.js', 'vite.config.ts'],
      deploymentType: 'static'
    },
    react: {
      installCommand: 'npm install',
      buildCommand: 'npm run build',
      buildDirectory: 'build',
      env: {},
      requiredDependencies: ['react-scripts', 'react-dom'],
      requiredFiles: [],
      deploymentType: 'static'
    },
    angular: {
      installCommand: 'npm install',
      buildCommand: 'npm run build',
      buildDirectory: 'dist',    
      env: {},
      requiredDependencies: ['@angular/core', 'angular.json'],
      requiredFiles: ['angular.json'],
      deploymentType: 'static'
    },
    angular_runtime: {
      installCommand: 'npm install',
      buildCommand: 'npm run build',
      buildDirectory: 'dist',
      env: {},
      requiredDependencies: ['@angular/core', '@nguniversal/express-engine'],
      requiredFiles: ['angular.json'],
      deploymentType: 'server',
      runtime: 'nodejs'
    },
    next_runtime: {
      installCommand: 'npm install',
      buildCommand: 'npm run build',
      buildDirectory: '.next',
      env: {},
      requiredDependencies: ['next'],
      requiredFiles: ['next.config.js', 'next.config.ts', 'next.config.mjs'],
      deploymentType: 'server',
      runtime: 'nodejs'
    },
    node_runtime: {
      installCommand: 'npm install',
      startCommand: 'node index.js',
      env: {},
      rootDirectory: '',
      requiredDependencies: ['express', 'fastify', 'koa', 'hapi'],
      requiredFiles: [],
      deploymentType: 'server',
      runtime: 'nodejs'
    }
  };


const path = require('path');
const fs = require('fs');

// Helper function to check if a file exists
const fileExists = (filePath) => {
  return fs.existsSync(filePath);
};

// Helper function to check if any required dependency is present
const hasAnyRequiredDependency = (requiredDependencies, dependencies) => {
  return requiredDependencies.some(dep => dependencies[dep]);
};

// Helper function to check if any required file is present
const hasAnyRequiredFile = (requiredFiles, files) => {
  return requiredFiles.some(file => files.includes(file));
};

// Main function to detect the framework
const detectFramework = (files, packageJson) => {
  const dependencies = { ...packageJson.dependencies, ...packageJson.devDependencies };

  // Iterate through all framework configurations
  for (const [framework, config] of Object.entries(farmworkConfig)) {
    const { requiredDependencies, requiredFiles } = config;

    // Check if the project has any of the required dependencies or files
    if (
      (requiredDependencies.length === 0 || hasAnyRequiredDependency(requiredDependencies, dependencies)) &&
      (requiredFiles.length === 0 || hasAnyRequiredFile(requiredFiles, files))
    ) {
      return {
        framework,
        config
      };
    }
  }

  // Fallback if no framework is detected
  return {
    framework: 'unknown',
    config: null
  };
};

const packageJson = require('./package.json');
const files = fs.readdirSync(path.resolve(__dirname));

console.log(files);
console.log(packageJson);

const detectedFramework = detectFramework(files, packageJson);
console.log(detectedFramework);