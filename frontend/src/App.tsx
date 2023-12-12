// import { useBlock } from "@starknet-react/core";
import Header from "./components/Header";
import { useState } from "react";

function App() {
  // State to keep track of form values
  const [formValues, setFormValues] = useState({
    name: "",
    symbol: "",
    decimals: "",
    type: "Classic", // default type
  });

  // Handle form input changes
  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    setFormValues({
      ...formValues,
      [e.target.name]: e.target.value,
    });
  };

  // Handle form submission
  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    console.log("Form Values: ", formValues);
    // Add your logic to deploy here
  };

  return (
    <main className=" flex flex-col items-center justify-center min-h-screen gap-12">
      <Header />
      {/* Form Start */}
      <form onSubmit={handleSubmit} className="w-full max-w-sm">
        <div className="mb-6">
          <label
            htmlFor="name"
            className="block mb-2 text-sm font-bold text-gray-700"
          >
            Name
          </label>
          <input
            type="text"
            id="name"
            name="name"
            value={formValues.name}
            onChange={handleChange}
            className="w-full px-3 py-2 leading-tight text-gray-700 border rounded shadow appearance-none focus:outline-none focus:shadow-outline"
          />
        </div>

        <div className="mb-6">
          <label
            htmlFor="symbol"
            className="block mb-2 text-sm font-bold text-gray-700"
          >
            Symbol
          </label>
          <input
            type="text"
            id="symbol"
            name="symbol"
            value={formValues.symbol}
            onChange={handleChange}
            className="w-full px-3 py-2 leading-tight text-gray-700 border rounded shadow appearance-none focus:outline-none focus:shadow-outline"
          />
        </div>

        <div className="mb-6">
          <label
            htmlFor="decimals"
            className="block mb-2 text-sm font-bold text-gray-700"
          >
            Decimals
          </label>
          <input
            type="text"
            id="decimals"
            name="decimals"
            value={formValues.decimals}
            onChange={handleChange}
            className="w-full px-3 py-2 leading-tight text-gray-700 border rounded shadow appearance-none focus:outline-none focus:shadow-outline"
          />
        </div>

        <div className="mb-6">
          <label
            htmlFor="type"
            className="block mb-2 text-sm font-bold text-gray-700"
          >
            Type
          </label>
          <select
            id="type"
            name="type"
            value={formValues.type}
            onChange={handleChange}
            className="w-full px-3 py-2 leading-tight text-gray-700 border rounded shadow appearance-none focus:outline-none focus:shadow-outline"
          >
            <option value="Classic">Classic</option>
            <option value="Elastic Supply">Elastic Supply</option>
          </select>
        </div>

        <div className="flex items-center justify-between">
          <button
            className="px-4 py-2 font-bold text-white bg-blue-500 rounded hover:bg-blue-700 focus:outline-none focus:shadow-outline"
            type="submit"
          >
            Deploy
          </button>
        </div>
      </form>
      {/* Form End */}
    </main>
  );
}

export default App;
