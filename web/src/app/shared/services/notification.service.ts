import { Injectable } from '@angular/core';
import { toast, ExternalToast } from 'ngx-sonner';

@Injectable({ providedIn: 'root' })
export class NotificationService {
  public success(
    message: string,
    description?: string,
    options?: Omit<ExternalToast, 'message' | 'description' | 'title' | 'type'>,
  ) {
    toast.success(message, this.buildOptions(description, options));
  }

  public error(
    message: string,
    description?: string,
    options?: Omit<ExternalToast, 'message' | 'description' | 'title' | 'type'>,
  ) {
    toast.error(message, this.buildOptions(description, options));
  }

  public danger(
    message: string,
    description?: string,
    options?: Omit<ExternalToast, 'message' | 'description' | 'title' | 'type'>,
  ) {
    toast.error(message, this.buildOptions(description, options));
  }

  public warning(
    message: string,
    description?: string,
    options?: Omit<ExternalToast, 'message' | 'description' | 'title' | 'type'>,
  ) {
    toast.warning(message, this.buildOptions(description, options));
  }

  public info(
    message: string,
    description?: string,
    options?: Omit<ExternalToast, 'message' | 'description' | 'title' | 'type'>,
  ) {
    toast.info(message, this.buildOptions(description, options));
  }

  private buildOptions(
    description?: string,
    options?: Omit<ExternalToast, 'message' | 'description' | 'title' | 'type'>,
  ): ExternalToast {
    return {
      ...options,
      description,
    };
  }
}
