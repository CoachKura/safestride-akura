export type SupabaseConfig = {
  url: string;
  anonKey: string;
  projectName?: string;
};

export type FieldSpec = { name: string; type: 'string' | 'number' | 'Date' | 'bit' };

export type WhereClause = { field: string; operator: string; value: any };

export type SortSpec = { field: string; direction: 'asc' | 'desc' };

export type DataObjectOptions = {
  viewName: string;
  fields?: FieldSpec[];
  whereClauses?: WhereClause[];
  sort?: SortSpec;
  recordLimit?: number;
  canInsert?: boolean;
  canUpdate?: boolean;
  canDelete?: boolean;
};

export type DataObject = {
  id: string;
  getData(): any[];
  onDataChanged(cb: (data: any[]) => void): void;
  insert(obj: Record<string, any>): Promise<any>;
  update(id: any, changes: Record<string, any>): Promise<any>;
  delete(id: any): Promise<any>;
  refresh(): Promise<void>;
  dispose(): void;
};
