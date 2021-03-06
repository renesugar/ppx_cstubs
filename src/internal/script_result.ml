(* This file is part of ppx_cstubs (https://github.com/fdopen/ppx_cstubs)
 * Copyright (c) 2018-2019 fdopen
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

let htl_expr = Hashtbl.create 64

let htl_used = Hashtbl.create 64

let htl_stri = Hashtbl.create 16

let foreign_used = ref false

let c_source = ref None

let clear () =
  Hashtbl.clear htl_expr;
  Hashtbl.clear htl_stri;
  Hashtbl.clear htl_used;
  foreign_used := false;
  c_source := None

type merlin_state = {
  hexpr : (Marshal_types.id * Mparsetree.Ast_cur.Parsetree.expression) list;
  hstri : (Marshal_types.id * Mparsetree.Ast_cur.Parsetree.structure_item) list;
  hused : (int * unit) list;
  fused : bool;
}

let merlin_save () =
  {
    hexpr = CCHashtbl.Poly.to_list htl_expr;
    hused = CCHashtbl.Poly.to_list htl_used;
    hstri = CCHashtbl.Poly.to_list htl_stri;
    fused = !foreign_used;
  }

let merlin_restore { hexpr; hused; hstri; fused } =
  let set htl l =
    Hashtbl.clear htl;
    List.iter (fun (a, b) -> Hashtbl.add htl a b) l
  in
  set htl_expr hexpr;
  set htl_used hused;
  set htl_stri hstri;
  foreign_used := fused
