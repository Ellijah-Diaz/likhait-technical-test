/**
 * Shared category list.
 *
 * Categories used to be a hard-coded constant, so every consumer trivially
 * agreed on them. Now that they are created at runtime the list has to be
 * fetched, and more than one part of the UI depends on it: the expense form
 * renders it as a dropdown while the "Add Category" dialog appends to it.
 * Keeping it in a context gives those consumers a single source of truth, so a
 * category added in the dialog is immediately selectable in the form without
 * either component knowing the other exists.
 */

import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { Category } from "../types";
import {
  createCategory as requestCreateCategory,
  fetchCategories,
} from "../services/api";

interface CategoriesContextValue {
  categories: Category[];
  isLoading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  addCategory: (name: string) => Promise<Category>;
}

const CategoriesContext = createContext<CategoriesContextValue | undefined>(
  undefined,
);

interface CategoriesProviderProps {
  children: React.ReactNode;
}

export function CategoriesProvider({ children }: CategoriesProviderProps) {
  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    setIsLoading(true);
    try {
      setCategories(await fetchCategories());
      setError(null);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to load categories",
      );
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const addCategory = useCallback(async (name: string) => {
    const created = await requestCreateCategory(name);

    // Insert locally instead of refetching. The server returns the index
    // sorted by name, so the same ordering is reproduced here to keep the
    // dropdown consistent with a later reload.
    setCategories((previous) =>
      [...previous, created].sort((a, b) => a.name.localeCompare(b.name)),
    );

    return created;
  }, []);

  const value = useMemo(
    () => ({ categories, isLoading, error, refresh, addCategory }),
    [categories, isLoading, error, refresh, addCategory],
  );

  return (
    <CategoriesContext.Provider value={value}>
      {children}
    </CategoriesContext.Provider>
  );
}

export function useCategories(): CategoriesContextValue {
  const context = useContext(CategoriesContext);

  if (!context) {
    throw new Error("useCategories must be used within a CategoriesProvider");
  }

  return context;
}
