import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { EnvironmentService } from './environment.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss',
  providers: [EnvironmentService]
})
export class AppComponent {
  title = 'SSRPOOP';
  apiUrl: string;
  constructor(private environmentService: EnvironmentService) {
    console.log('API URL:', this.environmentService.apiUrl);
    this.apiUrl = this.environmentService.apiUrl;
  }
}
