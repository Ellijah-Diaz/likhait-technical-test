/**
 * Form for creating a new expense category.
 */

import React, { useState } from "react";
import { Button, TextField } from "../vibes";
import { useCategories } from "../contexts/CategoriesContext";
import { Category } from "../types";

interface CategoryFormProps {
  onCreated?: (category: Category) => void;
  onCancel?: () => void;
}

export function CategoryForm({ onCreated, onCancel }: CategoryFormProps) {
  const { addCategory } = useCategories();
  const [name, setName] = useState("");
  const [error, setError] = useState<string | undefined>(undefined);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = (value: string) => {
    setName(value);
    if (error) {
      setError(undefined);
    }
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();

    const trimmedName = name.trim();
    if (!trimmedName) {
      setError("Category name is required");
      return;
    }

    setIsSubmitting(true);
    try {
      const created = await addCategory(trimmedName);
      setName("");
      onCreated?.(created);
    } catch (err) {
      // The API rejects duplicates and over-long names with a specific
      // message; show that rather than a generic failure.
      setError(
        err instanceof Error ? err.message : "Failed to create category",
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const formStyle: React.CSSProperties = {
    display: "flex",
    flexDirection: "column",
    gap: "1rem",
  };

  const buttonGroupStyle: React.CSSProperties = {
    display: "flex",
    gap: "0.5rem",
    marginTop: "0.5rem",
  };

  return (
    <form onSubmit={handleSubmit} style={formStyle} noValidate>
      <TextField
        label="Category name"
        type="text"
        placeholder="e.g. Subscriptions"
        value={name}
        onChange={(e) => handleChange(e.target.value)}
        error={error}
        maxLength={100}
        autoFocus
        fullWidth
        required
      />

      <div style={buttonGroupStyle}>
        <Button
          type="submit"
          variant="primary"
          disabled={isSubmitting}
          fullWidth
        >
          {isSubmitting ? "Adding..." : "Add Category"}
        </Button>
        {onCancel && (
          <Button
            type="button"
            variant="secondary"
            onClick={onCancel}
            disabled={isSubmitting}
          >
            Cancel
          </Button>
        )}
      </div>
    </form>
  );
}
