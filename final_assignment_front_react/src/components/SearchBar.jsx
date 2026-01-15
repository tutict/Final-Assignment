import React from 'react';

export default function SearchBar({ value, onChange, placeholder, actions }) {
  return (
    <div className="search-bar">
      <input
        type="text"
        value={value}
        onChange={(event) => onChange(event.target.value)}
        placeholder={placeholder || '搜索...'}
      />
      <div className="search-actions">{actions}</div>
    </div>
  );
}

