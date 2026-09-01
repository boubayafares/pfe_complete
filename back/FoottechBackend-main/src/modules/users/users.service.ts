import { UsersRepository } from './users.repository.js';
import type{ UpdateUserDto } from './users.dto.js';
import { NotFoundError } from '../../shared/errors/AppError.js';

function toSafeUser(user: Record<string, unknown>) {
  const { password_hash: _drop, ...rest } = user;
  return rest;
}

export class UsersService {
  private readonly repo = new UsersRepository();

  async getById(id: number) {
    const user = await this.repo.findById(id);
    if (!user) throw new NotFoundError('User');
    return toSafeUser(user as unknown as Record<string, unknown>);
  }

  async update(id: number, dto: UpdateUserDto) {
    const existing = await this.repo.findById(id);
    if (!existing) throw new NotFoundError('User');
    const payload: Record<string, unknown> = {};
    if (dto.firstName !== undefined) payload.first_name = dto.firstName;
    if (dto.lastName !== undefined) payload.last_name = dto.lastName;
    if (dto.email !== undefined) payload.email = dto.email;
    const updated = await this.repo.update(id, payload);
    return toSafeUser(updated as unknown as Record<string, unknown>);
  }

  async updateAvatar(id: number, publicUrl: string) {
    const existing = await this.repo.findById(id);
    if (!existing) throw new NotFoundError('User');
    const updated = await this.repo.update(id, { profile_image: publicUrl });
    return toSafeUser(updated as unknown as Record<string, unknown>);
  }
}
