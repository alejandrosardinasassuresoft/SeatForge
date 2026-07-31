# API Documentation (rswag / OpenAPI)

SeatForge usa **rswag** para documentar la API. Los specs OpenAPI sirven como tests (se ejecutan con `run_test!`) y como documentación interactiva en Swagger UI.

## Comandos

| Comando | Uso |
|---|---|
| `bundle exec rails server` | Levantar la API (default port 3000) |
| `bundle exec rails rswag:specs:swaggerize` | Regenerar `swagger/v1/swagger.yaml` desde los specs |
| `bundle exec rspec spec/integration/` | Ejecutar solo los specs de documentación |
| `bundle exec rspec` | Ejecutar toda la suite |

## URLs

| URL | Descripción |
|---|---|
| `http://localhost:3000/api-docs` | Swagger UI interactivo |
| `http://localhost:3000/api-docs/v1/swagger.yaml` | Spec OpenAPI 3.0.3 (JSON/raw) |

## Procedimiento para documentar un endpoint nuevo

### 1. Crear/editar el spec en `backend/spec/integration/api/v1/`

Un archivo por recurso (o agregar al existente):

```ruby
require "swagger_helper"

RSpec.describe "API V1 MisEndpoints", type: :request do
  path "/api/v1/mis_endpoints" do
    get("list mis_endpoints") do
      tags "MisEndpoints"
      produces "application/json"
      parameter name: :page, in: :query, type: :integer, required: false

      response "200", "mis_endpoints found" do
        schema "$ref" => "#/components/schemas/mi_schema"
        run_test!
      end
    end
  end
end
```

### 2. Agregar el schema del response (si es nuevo)

En `backend/spec/swagger_helper.rb`, dentro de `components.schemas`:

```ruby
mi_schema: {
  type: :object,
  properties: {
    id: { type: :integer },
    name: { type: :string }
  }
}
```

### 3. Regenerar la documentación

```bash
bundle exec rails rswag:specs:swaggerize
```

### 4. Verificar

Abrir `http://localhost:3000/api-docs` y confirmar que el endpoint aparece.

## Reglas clave

- Cada `path` + verbo HTTP (`get`/`post`) = una operación documentada.
- `response "200", "descripción"` define el código HTTP y el schema.
- Parámetros de path (`{id}`) requieren `let(:id)` definido en cada `response`.
- Cuerpos de request: `parameter name: :mi_body, in: :body, schema: { ... }`.
- Reutilizar schemas con `"$ref"` desde `swagger_helper.rb`; no duplicar.
- `run_test!` ejecuta la request real: el endpoint debe existir y responder, o el spec falla.
- Un solo `response` por código HTTP (rswag solo conserva el último con el mismo código).
- Después de regenerar, correr `bundle exec rspec` para confirmar que nada se rompió.
