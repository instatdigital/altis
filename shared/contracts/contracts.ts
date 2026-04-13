/**
 * Altis backend transport contracts.
 *
 * These are the canonical TypeScript shapes for all online transport
 * boundaries. Backend response mappers and client-side gateway
 * implementations MUST conform to these types.
 *
 * Rules:
 * - These are transport read/write models, not domain entities.
 * - All dates are ISO-8601 strings in transit.
 * - `mode` on project and board is always 'online' in this family.
 */

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

export interface SessionUserContract {
  userId: string;
  email: string | null;
}

export interface ErrorEnvelopeContract {
  statusCode: number;
  error: string;
  message: string | string[];
  path: string;
  timestamp: string;
}

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------

export interface ProfileReadModel {
  userId: string;
  email: string | null;
  name: string | null;
  createdAt: string;
  updatedAt: string;
}

// ---------------------------------------------------------------------------
// Project
// ---------------------------------------------------------------------------

export interface OnlineProjectReadModel {
  projectId: string;
  mode: 'online';
  name: string;
  createdAt: string;
  updatedAt: string;
}

export interface OnlineProjectCreateWriteModel {
  name: string;
}

// ---------------------------------------------------------------------------
// Board & Stage
// ---------------------------------------------------------------------------

export type BoardStageKind = 'regular' | 'terminalSuccess' | 'terminalFailure';

export interface OnlineBoardStageReadModel {
  stageId: string;
  boardId: string;
  name: string;
  orderIndex: number;
  kind: BoardStageKind;
  createdAt: string;
  updatedAt: string;
}

export interface OnlineBoardReadModel {
  boardId: string;
  projectId: string;
  mode: 'online';
  name: string;
  stages: OnlineBoardStageReadModel[];
  createdAt: string;
  updatedAt: string;
}

export interface OnlineBoardContentReadModel {
  boardId: string;
  projectId: string;
  stages: OnlineBoardStageReadModel[];
  tasks: OnlineTaskReadModel[];
}

export interface OnlineBoardCreateWriteModel {
  name: string;
  stages?: Array<{ name: string; kind: BoardStageKind }>;
}

export interface OnlineStageCreateWriteModel {
  name: string;
}

export interface OnlineStageRenameWriteModel {
  name: string;
}

export interface OnlineStageReorderWriteModel {
  stageIds: string[];
}

// ---------------------------------------------------------------------------
// Task
// ---------------------------------------------------------------------------

export type TaskStatus = 'active' | 'completed' | 'failed';

export interface OnlineTaskReadModel {
  taskId: string;
  projectId: string;
  boardId?: string;
  stageId?: string;
  title: string;
  status: TaskStatus;
  createdAt: string;
  updatedAt: string;
}

export interface OnlineTaskCreateWriteModel {
  title: string;
  stageId?: string;
}

export interface OnlineTaskUpdateWriteModel {
  title?: string;
}

export interface OnlineTaskStageMoveWriteModel {
  stageId: string;
}
