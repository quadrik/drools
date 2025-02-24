/*
 * Copyright 2023 Red Hat, Inc. and/or its affiliates.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 *
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.drools.drlonyaml.model;

import java.util.ArrayList;
import java.util.List;

import org.drools.drl.ast.descr.FunctionDescr;
import org.drools.drl.ast.descr.ImportDescr;
import org.drools.drl.ast.descr.PackageDescr;
import org.drools.drl.ast.descr.RuleDescr;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonInclude.Include;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;

@JsonPropertyOrder({"name", "imports", "rules", "functions"})
public class DrlPackage {
    @JsonInclude(Include.NON_EMPTY)
    private String name = ""; // default empty, consistent with DRL parser.
    @JsonInclude(Include.NON_EMPTY)
    private List<Import> imports = new ArrayList<>();
    private List<Rule> rules = new ArrayList<>();
    @JsonInclude(Include.NON_EMPTY)
    private List<Function> functions = new ArrayList<>();
    
    public static DrlPackage from(PackageDescr o) {
        DrlPackage result = new DrlPackage();
        result.name = o.getName();
        for (ImportDescr i : o.getImports()) {
            result.imports.add(Import.from(i));
        }
        for (RuleDescr r : o.getRules()) {
            result.rules.add(Rule.from(r));
        }
        for (FunctionDescr f : o.getFunctions()) {
            result.functions.add(Function.from(f));
        }
        return result;
    }

    public String getName() {
        return name;
    }

    public List<Import> getImports() {
        return imports;
    }

    public List<Rule> getRules() {
        return rules;
    }
    
    public List<Function> getFunctions() {
        return functions;
    }
}
