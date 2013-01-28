ActivityScraperApp::Application.routes.draw do
  
  get 'search' => 'pages#search', defaults: {format: :json}
  
end
