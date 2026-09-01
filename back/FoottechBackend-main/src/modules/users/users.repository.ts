import { BaseRepository } from '../../shared/database/BaseRepository.js';
import type{ UserRecord } from './users.interface.js';

export class UsersRepository extends BaseRepository<UserRecord> {
  constructor() {
    super('users');
  }
}
