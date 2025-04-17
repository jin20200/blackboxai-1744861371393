# Frontend Guide

This document outlines the frontend architecture, components, and development guidelines for the Event Manager system.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Component Structure](#component-structure)
- [State Management](#state-management)
- [Routing](#routing)
- [Styling](#styling)
- [API Integration](#api-integration)
- [Testing Strategy](#testing-strategy)
- [Performance Optimization](#performance-optimization)
- [Security Measures](#security-measures)
- [Best Practices](#best-practices)

## Architecture Overview

### Technology Stack

```yaml
frontend_stack:
  framework: React
  language: TypeScript
  styling: Tailwind CSS
  state: Redux Toolkit
  routing: React Router
  api: Axios
  testing: Jest + React Testing Library
  bundler: Webpack
```

### Project Structure

```
frontend/
├── src/
│   ├── components/
│   │   ├── common/
│   │   ├── features/
│   │   └── layouts/
│   ├── pages/
│   ├── hooks/
│   ├── services/
│   ├── store/
│   ├── utils/
│   └── styles/
├── public/
├── tests/
└── config/
```

## Component Structure

### Component Organization

```typescript
// Component template
interface ComponentProps {
  // Props definition
}

const Component: React.FC<ComponentProps> = ({ prop1, prop2 }) => {
  // Component logic
  const [state, setState] = useState(initialState);
  
  // Effects
  useEffect(() => {
    // Side effects
  }, [dependencies]);
  
  // Event handlers
  const handleEvent = () => {
    // Event handling logic
  };
  
  // Render
  return (
    <div className="component">
      {/* Component JSX */}
    </div>
  );
};
```

### Common Components

```typescript
// Button component
const Button: React.FC<ButtonProps> = ({
  variant = 'primary',
  size = 'medium',
  children,
  onClick
}) => (
  <button
    className={`btn btn-${variant} btn-${size}`}
    onClick={onClick}
  >
    {children}
  </button>
);

// Card component
const Card: React.FC<CardProps> = ({
  title,
  content,
  footer
}) => (
  <div className="card">
    <div className="card-header">{title}</div>
    <div className="card-content">{content}</div>
    <div className="card-footer">{footer}</div>
  </div>
);
```

## State Management

### Redux Store

```typescript
// Store configuration
const store = configureStore({
  reducer: {
    auth: authReducer,
    events: eventsReducer,
    guests: guestsReducer
  },
  middleware: [
    ...getDefaultMiddleware(),
    logger,
    api
  ]
});

// Slice example
const eventSlice = createSlice({
  name: 'events',
  initialState,
  reducers: {
    setEvents: (state, action) => {
      state.items = action.payload;
    },
    addEvent: (state, action) => {
      state.items.push(action.payload);
    },
    updateEvent: (state, action) => {
      const index = state.items.findIndex(
        item => item.id === action.payload.id
      );
      if (index !== -1) {
        state.items[index] = action.payload;
      }
    }
  }
});
```

### Custom Hooks

```typescript
// Custom hook example
const useAuth = () => {
  const dispatch = useDispatch();
  const user = useSelector(selectUser);
  
  const login = async (credentials) => {
    try {
      const response = await authService.login(credentials);
      dispatch(setUser(response.data));
    } catch (error) {
      handleError(error);
    }
  };
  
  const logout = () => {
    dispatch(clearUser());
  };
  
  return { user, login, logout };
};
```

## Routing

### Route Configuration

```typescript
// Route definitions
const routes = [
  {
    path: '/',
    component: Home,
    exact: true
  },
  {
    path: '/events',
    component: Events,
    routes: [
      {
        path: '/events/:id',
        component: EventDetails
      }
    ]
  },
  {
    path: '/admin',
    component: Admin,
    protected: true,
    role: 'admin'
  }
];

// Route component
const AppRouter: React.FC = () => (
  <Router>
    <Switch>
      {routes.map(route => (
        <Route
          key={route.path}
          path={route.path}
          exact={route.exact}
          render={props => (
            <route.component {...props} routes={route.routes} />
          )}
        />
      ))}
    </Switch>
  </Router>
);
```

## Styling

### Tailwind Configuration

```javascript
// tailwind.config.js
module.exports = {
  content: ['./src/**/*.{js,jsx,ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: '#007bff',
        secondary: '#6c757d'
      },
      spacing: {
        '72': '18rem',
        '84': '21rem',
        '96': '24rem'
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif']
      }
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography')
  ]
};
```

### Component Styling

```typescript
// Styled component example
const StyledCard = ({ children }) => (
  <div className="
    bg-white
    rounded-lg
    shadow-md
    p-6
    hover:shadow-lg
    transition-shadow
    duration-300
  ">
    {children}
  </div>
);

// Responsive design
const ResponsiveGrid = ({ items }) => (
  <div className="
    grid
    grid-cols-1
    sm:grid-cols-2
    md:grid-cols-3
    lg:grid-cols-4
    gap-4
  ">
    {items.map(item => (
      <GridItem key={item.id} {...item} />
    ))}
  </div>
);
```

## API Integration

### API Service

```typescript
// API client configuration
const apiClient = axios.create({
  baseURL: process.env.REACT_APP_API_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// API service
const eventService = {
  getEvents: async (params) => {
    const response = await apiClient.get('/events', { params });
    return response.data;
  },
  
  createEvent: async (data) => {
    const response = await apiClient.post('/events', data);
    return response.data;
  },
  
  updateEvent: async (id, data) => {
    const response = await apiClient.put(`/events/${id}`, data);
    return response.data;
  }
};
```

## Testing Strategy

### Component Testing

```typescript
// Component test example
describe('EventCard', () => {
  it('renders event details correctly', () => {
    const event = {
      title: 'Test Event',
      date: '2024-01-01',
      location: 'Test Location'
    };
    
    render(<EventCard event={event} />);
    
    expect(screen.getByText(event.title)).toBeInTheDocument();
    expect(screen.getByText(event.date)).toBeInTheDocument();
    expect(screen.getByText(event.location)).toBeInTheDocument();
  });
  
  it('handles click events', () => {
    const onClickMock = jest.fn();
    render(<EventCard onClick={onClickMock} />);
    
    fireEvent.click(screen.getByRole('button'));
    expect(onClickMock).toHaveBeenCalled();
  });
});
```

## Performance Optimization

### Optimization Techniques

```typescript
// Code splitting
const LazyComponent = React.lazy(() => import('./LazyComponent'));

// Memoization
const MemoizedComponent = React.memo(({ prop }) => (
  <div>{prop}</div>
));

// Performance hooks
const useMemoizedValue = (value) => {
  return useMemo(() => expensiveCalculation(value), [value]);
};

// Image optimization
const OptimizedImage = ({ src, alt }) => (
  <img
    src={src}
    alt={alt}
    loading="lazy"
    className="w-full h-auto"
    onLoad={handleImageLoad}
  />
);
```

## Security Measures

### Security Best Practices

```typescript
// XSS prevention
const sanitizeHtml = (html: string): string => {
  return DOMPurify.sanitize(html);
};

// CSRF protection
apiClient.interceptors.request.use(config => {
  config.headers['X-CSRF-Token'] = getCsrfToken();
  return config;
});

// Authentication
const PrivateRoute: React.FC<PrivateRouteProps> = ({
  component: Component,
  ...rest
}) => {
  const { isAuthenticated } = useAuth();
  
  return (
    <Route
      {...rest}
      render={props =>
        isAuthenticated ? (
          <Component {...props} />
        ) : (
          <Redirect to="/login" />
        )
      }
    />
  );
};
```

## Best Practices

### Coding Standards

```typescript
// Component naming
const UserProfile: React.FC = () => { ... };

// Props typing
interface ButtonProps {
  variant: 'primary' | 'secondary';
  size: 'small' | 'medium' | 'large';
  onClick: () => void;
  children: React.ReactNode;
}

// Error boundaries
class ErrorBoundary extends React.Component {
  componentDidCatch(error: Error, info: React.ErrorInfo) {
    logError(error, info);
  }
  
  render() {
    return this.props.children;
  }
}
```

### Performance Guidelines

1. Use React.memo for pure components
2. Implement code splitting
3. Optimize images and assets
4. Minimize re-renders
5. Use proper key props
6. Implement proper error boundaries
7. Optimize bundle size
8. Use performance monitoring

## Resources

- [React Documentation](https://reactjs.org/docs)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Redux Toolkit Documentation](https://redux-toolkit.js.org/)
- [Frontend Best Practices](./docs/frontend-best-practices.md)
