from cheby.hdl.elgen import ElGen
from cheby.hdl.genreg import GenReg
from cheby.hdl.geninterface import GenInterface
from cheby.hdl.genmemory import GenMemory
from cheby.hdl.gensubmap import GenSubmap
from cheby.hdltree import HDLInterface, HDLInterfaceArray, HDLInterfaceIndex
import cheby.tree as tree
from cheby.layout import ilog2

class GenBlock(ElGen):
    def create_generators(self):
        """Add the object to generate hdl"""
        for n in self.n.children:
            if isinstance(n, tree.RepeatBlock):
                n.h_gen = GenRepeatBlock(self.root, self.module, n)
            elif isinstance(n, tree.Block):
                n.h_gen = GenBlock(self.root, self.module, n)
            elif isinstance(n, tree.Submap):
                if n.include is True:
                    # Inline
                    n.h_gen = GenBlock(self.root, self.module, n.c_submap)
                elif n.filename is None:
                    # A pure interface
                    n.c_bus_access = 'rw'
                    n.h_gen = GenInterface(self.root, self.module, n)
                else:
                    # A submap defined in a file
                    n.h_gen = GenSubmap(self.root, self.module, n)
            elif isinstance(n, tree.Memory):
                if n.interface is not None:
                    n.c_addr_bits = ilog2(n.c_depth)
                    n.c_width = n.c_elsize * tree.BYTE_SIZE
                    n.c_bus_access = n.c_mem_access
                    n.h_gen = GenInterface(self.root, self.module, n)
                else:
                    n.h_gen = GenMemory(self.root, self.module, n)
            elif isinstance(n, tree.Reg):
                n.h_gen = GenReg(self.root, self.module, n)
            else:
                raise AssertionError
            n.h_gen.create_generators()

    def gen_ports(self):
        if self.n.hdl_iogroup is not None:
            if self.root.h_itf:
                print("nested interface is ignored")
                self.root.hdl_iogroup = None
            else:
                self.root.h_itf = HDLInterface('t_' + self.n.hdl_iogroup)
                self.module.global_decls.append(self.root.h_itf)
                self.root.h_ports = self.module.add_modport(self.n.hdl_iogroup, self.root.h_itf, True)
                if isinstance(self.n, tree.Root):
                    self.root.h_ports.comment = "Wires and registers"

        for n in self.n.children:
            n.h_gen.gen_ports()

        if self.n.hdl_iogroup is not None:
            self.root.h_itf = None
            self.root.h_ports = self.module

    def gen_processes(self, ibus):
        for n in self.n.children:
            n.h_gen.gen_processes(ibus)

    def gen_read(self, s, off, ibus, rdproc):
        raise AssertionError

    def gen_write(self, s, off, ibus, wrproc):
        raise AssertionError


class GenRepeatBlock(GenBlock):
    def gen_ports(self):
        if self.n.hdl_iogroup is not None:
            prev_itf = self.root.h_itf
            prev_ports = self.root.h_ports
            itf = HDLInterface('t_' + self.n.hdl_iogroup)
            itf_arr = HDLInterfaceArray(itf, self.n.count)
            self.root.h_itf = itf_arr
            self.module.global_decls.append(itf_arr)
            ports_arr = self.module.add_modport(self.n.hdl_iogroup, itf_arr, is_master=True)

            for i, n in enumerate(self.n.children):
                itf_arr.first_index = (i == 0)
                if n.hdl_blk_prefix:            
                    itf_arr.name_prefix = n.c_name + '_'
                else:
                    itf_arr.name_suffix = n.c_name
                self.root.h_ports = HDLInterfaceIndex(ports_arr, i)
                n.h_gen.gen_ports()

            self.root.h_itf = prev_itf
            self.root.h_ports = prev_ports
        else:
            for n in self.n.children:
                n.h_gen.gen_ports()


