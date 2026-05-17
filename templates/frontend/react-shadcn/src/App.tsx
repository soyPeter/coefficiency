import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Separator } from "@/components/ui/separator"
import { Toaster, toast } from "@/components/ui/sonner"
import { PlusIcon, RefreshCwIcon, SearchIcon } from "lucide-react"

const API_BASE = "/api/v1/__TABLE_URL__"

interface Entity {
  id: string
  name: string
  description: string
  createdAt: string
}

function App() {
  const [items, setItems] = useState<Entity[]>([])
  const [loading, setLoading] = useState(true)
  const [name, setName] = useState("")
  const [description, setDescription] = useState("")

  async function fetchItems() {
    setLoading(true)
    try {
      const res = await fetch(API_BASE)
      if (res.ok) {
        setItems(await res.json())
      }
    } catch {
      // Backend may not be running
    } finally {
      setLoading(false)
    }
  }

  async function createItem() {
    try {
      const res = await fetch(API_BASE, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, description }),
      })
      if (res.ok) {
        toast.success("Item created")
        setName("")
        setDescription("")
        fetchItems()
      }
    } catch {
      toast.error("Failed to create item")
    }
  }

  useEffect(() => {
    fetchItems()
  }, [])

  return (
    <div className="container mx-auto p-6 space-y-6">
      <header className="flex items-center justify-between">
        <div>
          <h1 className="font-heading text-2xl font-medium">__SERVICE_PASCAL__</h1>
          <p className="text-sm text-muted-foreground">
            Manage your __TABLE_URL__ resources
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={fetchItems}>
            <RefreshCwIcon />
            Refresh
          </Button>
          <Dialog>
            <DialogTrigger asChild>
              <Button size="sm">
                <PlusIcon />
                New
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Create __ENTITY__</DialogTitle>
              </DialogHeader>
              <div className="space-y-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Name</label>
                  <Input
                    placeholder="Enter name"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Description</label>
                  <Input
                    placeholder="Enter description"
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                  />
                </div>
                <Button onClick={createItem} className="w-full">
                  Create
                </Button>
              </div>
            </DialogContent>
          </Dialog>
        </div>
      </header>

      <Separator />

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardHeader>
            <CardTitle>Total Items</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-heading font-medium">{items.length}</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>Status</CardTitle>
          </CardHeader>
          <CardContent>
            <Badge variant={loading ? "secondary" : "default"}>
              {loading ? "Loading" : "Connected"}
            </Badge>
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>API</CardTitle>
          </CardHeader>
          <CardContent>
            <code className="text-xs text-muted-foreground">{API_BASE}</code>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>__TABLE_URL__</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex items-center justify-center py-8 text-muted-foreground">
              <RefreshCwIcon className="animate-spin mr-2" />
              Loading...
            </div>
          ) : items.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-8 text-muted-foreground gap-2">
              <SearchIcon className="size-8" />
              <p>No items found. Create one to get started.</p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Description</TableHead>
                  <TableHead>Created</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {items.map((item) => (
                  <TableRow key={item.id}>
                    <TableCell className="font-medium">{item.name}</TableCell>
                    <TableCell className="text-muted-foreground">
                      {item.description || "—"}
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      {new Date(item.createdAt).toLocaleDateString()}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <Toaster />
    </div>
  )
}

export default App
