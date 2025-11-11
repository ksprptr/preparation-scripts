/**
 * Function to get a string environment variable
 */
export const getEnvString = (key: string): string => {
  const value = process.env[key];

  if (!value) {
    throw new Error(`Config value for key "${key}" is not set`);
  }

  return value;
};

/**
 * Function to get a number environment variable
 */
export const getEnvNumber = (key: string): number => {
  const value = getEnvString(key);
  const numberValue = Number(value);

  if (isNaN(numberValue)) {
    throw new Error(`Config value for key "${key}" is not a number`);
  }

  return numberValue;
};
