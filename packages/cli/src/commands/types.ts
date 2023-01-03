import { Arguments, CommandBuilder } from "yargs";
import { generateTypes } from "../utils";

type Options = {
  abiDir?: string;
  outputDir: string;
  config: string;
};

export const command = "types";
export const desc = "Generates typescript types for contracts and systems.";

export const builder: CommandBuilder<Options, Options> = (yargs) =>
  yargs.options({
    abiDir: {
      type: "string",
      description: "Input directory of existing ABI to use to generate types. If not provided, contracts are built.",
    },
    outputDir: {
      type: "string",
      description: "Output directory for generated types. Defaults to ./types",
      default: "./types",
    },
    config: { type: "string", default: "./deploy.json", desc: "Component and system deployment configuration" },
  });

export const handler = async (args: Arguments<Options>): Promise<void> => {
  const { abiDir, outputDir, config } = args;
  await generateTypes(config, abiDir, outputDir, { clear: true });
};
