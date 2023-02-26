import { StoreUserConfig } from "@latticexyz/cli";
import { SchemaType } from "@latticexyz/schema-type";

const config: StoreUserConfig = {
  storeImportPath: "../",

  tables: {
    // TODO these arrays require push/pull to be implemented
    /*AddressArray: {
      schema: {
        addresses: SchemaType.ADDRESS_ARRAY,
      }
    },
    CallbackArray: {
      schema: {
        callbacks: SchemaType.BYTES24_ARRAY,
      }
    },*/
    Mixed: {
      schema: {
        u32: SchemaType.UINT32,
        u128: SchemaType.UINT128,
        a32: SchemaType.UINT32_ARRAY,
        s: SchemaType.STRING,
      },
    },
    Route: {
      schema: {
        addr: SchemaType.ADDRESS,
        selector: SchemaType.BYTES4,
        executionMode: SchemaType.UINT8,
      },
    },
    Vector2: {
      schema: {
        x: SchemaType.UINT32,
        y: SchemaType.UINT32,
      },
    },
    // default ECS component
    AttackComponent: SchemaType.UINT32,
    // reusable schema where you pass your own tableId
    Vector2Schema: {
      schemaMode: true,
      schema: {
        x: SchemaType.UINT32,
        y: SchemaType.UINT32,
      },
    },
    // force a component to be a table
    AttackTable: {
      disableComponentMode: true,
      schema: {
        attack: SchemaType.UINT32,
      }
    },
    // singleton component
    IsPaused: {
      keyTuple: [],
      schema: {
        value: SchemaType.BOOL,
      }
    },
    // singleton table
    MyConfig: {
      keyTuple: [],
      schema: {
        isPaused: SchemaType.BOOL,
        value2: SchemaType.UINT32,
        someBlob: SchemaType.BYTES,
        someNumbers: SchemaType.UINT256_ARRAY
      },
    },
    // singleton schema
    Config: {
      keyTuple: [],
      schemaMode: true,
      schema: {
        isPaused: SchemaType.BOOL,
        value2: SchemaType.UINT32,
        someBlob: SchemaType.BYTES,
        someNumbers: SchemaType.UINT256_ARRAY
      },
    },
  },
};

export default config;
